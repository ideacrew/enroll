# frozen_string_literal: true

start_time = Time.now - 17.minutes
end_time = Time.now

class IvlEnrollmentsPublisher
  extend Acapi::Notifiers

  def self.publish_action(action_name, hbx_id, action)
    reply_to = "#{Rails.application.config.acapi.hbx_id}.#{Rails.application.config.acapi.environment_name}.q.glue.enrollment_event_batch_handler"

    Rails.logger.info "publish_action: action_name = #{action_name}, reply_to = #{reply_to}, hbx_enrollment_id = #{hbx_id}, enrollment_action_uri = #{action}"
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

def can_transmit?(enrollment)
  # We need to replace this.
  # It currently checks if we offer the plan attached to the enrollment.
  # However, it uses the **current** address of the covered individuals.
  # This means that when you move, resulting in a termination, the termination
  # event will no longer flow, because all of a sudden, the plan isn't offered -
  # which is correct.  What we need to check for instead is an **actual**
  # $0 premium.  I'm leaving the operation intact as I'm not sure where
  # else it might be used.

  # offered_in_service_area = ::Operations::Products::ProductOfferedInServiceArea.new.call({enrollment: enrollment})
  # offered_in_service_area.success?

  enrollment.total_premium > 0.0
end

enrollment_kinds = %w(employer_sponsored employer_sponsored_cobra)
active_statuses = %w[coverage_selected auto_renewing renewing_coverage_selected]

query = Queries::IvlSepEvents.new(start_time, end_time)

purchases = query.selections_during_window
terms = query.terminations_during_window

puts purchases.count unless Rails.env.test?
puts terms.count unless Rails.env.test?

purchase_event = "acapi.info.events.hbx_enrollment.coverage_selected"
purchases.to_a.each do |rec|
  pol_id = rec["_id"]
  enrollment = HbxEnrollment.where(hbx_id: pol_id).first
  next unless enrollment.present?

  unless can_transmit?(enrollment)
    Rails.logger.info "0$ premium issue - cannot transmit purchase #{pol_id}"
    next
  end

  if query.purchase_and_cancel_in_same_window?(enrollment)
    Rails.logger.info "Purchase and cancel in same window, ignoring initial event for #{pol_id}"
    next
  end

  if ::EnrollRegistry.feature_enabled?(:gate_enrollments_to_edidb_for_year)
    next if enrollment.coverage_year == EnrollRegistry[:gate_enrollments_to_edidb_for_year].setting(:year).item
  end
  Rails.logger.info "-----publishing #{pol_id}"

  if rec["enrollment_state"] == 'auto_renewing' || is_retro_renewal_enrollment?(enrollment)
    IvlEnrollmentsPublisher.publish_action(purchase_event, pol_id, "urn:openhbx:terms:v1:enrollment#auto_renew")
  else
    IvlEnrollmentsPublisher.publish_action(purchase_event, pol_id, "urn:openhbx:terms:v1:enrollment#initial")
  end

  Rails.logger.info "Published event: #{purchase_event} for enrollment hbx_id: #{pol_id}"
  enrollment.mark_purchase_event_as_published!
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
  if query.purchase_and_cancel_in_same_window?(enrollment) && query.skip_termination?(enrollment)
    Rails.logger.info "Purchase and cancel in same window, ignoring term event for #{pol_id}"
    next
  end
  if query.has_silent_cancel?(enrollment)
    Rails.logger.info "Silent cancel, ignoring term event for #{pol_id}"
    next
  end
  if ::EnrollRegistry.feature_enabled?(:gate_enrollments_to_edidb_for_year)
    next if enrollment.coverage_year == EnrollRegistry[:gate_enrollments_to_edidb_for_year].setting(:year).item
  end
  Rails.logger.info "-----publishing #{pol_id}"
  IvlEnrollmentsPublisher.publish_action(term_event, pol_id, "urn:openhbx:terms:v1:enrollment#terminate_enrollment")
  Rails.logger.info "Published event: #{term_event} for enrollment hbx_id: #{pol_id}"
rescue StandardError => e
  Rails.logger.info "Error while processing term #{rec['_id']} - #{e}"
end
