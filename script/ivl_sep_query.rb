start_time = Time.now - 17.minutes
end_time = Time.now

class IvlEnrollmentsPublisher
  extend Acapi::Notifiers

  def self.publish_action(action_name, hbx_id, action)
    reply_to = "#{Rails.application.config.acapi.hbx_id}.#{Rails.application.config.acapi.environment_name}.q.glue.enrollment_event_batch_handler"

    notify(
      action_name, {
      :reply_to => reply_to,
      :hbx_enrollment_id => hbx_id,
      :enrollment_action_uri => action
    })
  end
end

def is_retro_renewal_enrollment?(enrollment)
  return false unless enrollment.present?
  return false if enrollment.is_shop?
  last_date= enrollment.effective_on - 1
  active_enrollment = enrollment.family.hbx_enrollments.where(:kind => enrollment.kind,
                                          :aasm_state.in => (HbxEnrollment::ENROLLED_STATUSES - ["coverage_termination_pending"]),
                                          :coverage_kind => enrollment.coverage_kind,
                                          :effective_on => { "$gte" => last_date.beginning_of_year, "$lt" => last_date}).first
  return false unless active_enrollment.present?
  return false unless active_enrollment.product.renewal_product == enrollment.product
  enrollment.workflow_state_transitions.where(from_state: 'auto_renewing', to_state: 'coverage_selected').present?
end

# TODO - Refactor this and move this into event source
# def publish_cv3_family(event_name, hbx_enrollment)
#   ::Operations::HbxEnrollments::PublishChangeEvent.new.call({
#     event_name: event_name,
#     enrollment: hbx_enrollment
#   })
# rescue StandardError => e
#   Rails.logger.info "Error while publishing cv3_family for #{event_name} enrollment #{enrollment.id}  - #{e}"
# end

def can_transmit?(enrollment)
  offered_in_service_area = ::Operations::Products::ProductOfferedInServiceArea.new.call({enrollment: enrollment})
  offered_in_service_area.success?
end

enrollment_kinds = %w(employer_sponsored employer_sponsored_cobra)
active_statuses = %w[coverage_selected auto_renewing renewing_coverage_selected]

purchases = HbxEnrollment.collection.aggregate([
  {"$match" => {
    "workflow_state_transitions" => {
      "$elemMatch" => {
        "to_state" => {"$in" => active_statuses},
        "transition_at" => {
           "$gte" => start_time,
           "$lt" => end_time
        }
      }
    },
    "rating_area_id" => {"$ne" => nil},
    "kind" => {"$nin" => enrollment_kinds}
  }},
  {"$group" => {
    "_id" => "$hbx_id",
    "created_at" => { "$last" =>  "$created_at" },
    "enrollment_state" => {"$last" => "$aasm_state"}
  }},
  {"$project" => {
    "_id" => 1,
    "created_at" => 1,
    "enrollment_state" => "$enrollment_state"
  }},
  { "$sort" => { "created_at" => 1 } }
])

terms = HbxEnrollment.collection.aggregate([
  {"$match" => {
    "workflow_state_transitions" => {
      "$elemMatch" => {
        "to_state" => {"$in" => ["coverage_terminated","coverage_canceled"]},
        "transition_at" => {
           "$gte" => start_time,
           "$lt" => end_time
        }
      }
    },
    "rating_area_id" => {"$ne" => nil},
    "kind" => {"$nin" => enrollment_kinds},
  }},
  {"$group" => {
      "_id" => "$hbx_id",
      "created_at" => { "$last" =>  "$created_at" },
  }},
  { "$sort" => { "created_at" => 1 } }
])

puts purchases.count
puts terms.count

purchase_event = "acapi.info.events.hbx_enrollment.coverage_selected"
purchases.to_a.each do |rec|
  pol_id = rec["_id"]
  enrollment = HbxEnrollment.where(hbx_id: pol_id).first
  next unless enrollment.present?

  unless can_transmit?(enrollment)
    Rails.logger.info "0$ premium issue - cannot transmit purchase #{pol_id}"
    next
  end

  if ::EnrollRegistry.feature_enabled?(:gate_enrollments_to_edidb_for_year)
    next if enrollment.coverage_year == EnrollRegistry[:gate_enrollments_to_edidb_for_year].setting(:year).item
  end
  Rails.logger.info "-----publishing #{pol_id}"

  if rec["enrollment_state"] == 'auto_renewing' || is_retro_renewal_enrollment?(enrollment)
    IvlEnrollmentsPublisher.publish_action(purchase_event, pol_id, "urn:openhbx:terms:v1:enrollment#auto_renew")
    # TODO - Refactor this and move this into event source
    # publish_cv3_family('auto_renew', enrollment)
  else
    IvlEnrollmentsPublisher.publish_action(purchase_event, pol_id, "urn:openhbx:terms:v1:enrollment#initial")
    # TODO - Refactor this and move this into event source
    # publish_cv3_family('initial_purchase', enrollment)
  end
rescue StandardError => e
  Rails.logger.info "Error while processing purchase #{rec['_id']} - #{e}"
end

term_event = "acapi.info.events.hbx_enrollment.terminated"
terms.to_a.each do |rec|
  pol_id = rec["_id"]
  enrollment = HbxEnrollment.where(hbx_id: pol_id).first
  next unless enrollment.present?

  unless can_transmit?(enrollment)
    Rails.logger.info "0$ premium issue - cannot trasmit term #{pol_id}"
    next
  end
  if ::EnrollRegistry.feature_enabled?(:gate_enrollments_to_edidb_for_year)
    next if enrollment.coverage_year == EnrollRegistry[:gate_enrollments_to_edidb_for_year].setting(:year).item
  end
  Rails.logger.info "-----publishing #{pol_id}"
  IvlEnrollmentsPublisher.publish_action(term_event, pol_id, "urn:openhbx:terms:v1:enrollment#terminate_enrollment")
  # TODO - Refactor this and move this into event source
  # publish_cv3_family('terminated', enrollment)
rescue StandardError => e
  Rails.logger.info "Error while processing term #{rec['_id']} - #{e}"
end
