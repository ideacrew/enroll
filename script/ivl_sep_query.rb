start_time = Time.now - 17.minutes
end_time = Time.now

class IvlEnrollmentsPublisher
  extend Acapi::Notifiers

  def self.publish_action(action_name, hbx_id, action)
    puts hbx_id.to_s

    glue_environment = "prod"
    reply_to = "dc0.#{glue_environment}.q.glue.enrollment_event_batch_handler"

    notify(
      action_name, {
      :reply_to => reply_to,
      :hbx_enrollment_id => hbx_id,
      :enrollment_action_uri => action
    })
  end
end

enrollment_kinds = %w(employer_sponsored employer_sponsored_cobra)
coverage_statuses = %w(coverage_selected auto_renewing)

purchases = Family.collection.aggregate([
  {"$match" => {
    "households.hbx_enrollments.workflow_state_transitions" => {
      "$elemMatch" => {
        "to_state" => {"$in" => coverage_statuses},
        "transition_at" => {
           "$gte" => start_time,
           "$lt" => end_time
        }
      }
    }
  }},
  {"$unwind" => "$households"},
  {"$unwind" => "$households.hbx_enrollments"},
  {"$match" => {
    "households.hbx_enrollments.workflow_state_transitions" => {
      "$elemMatch" => {
        "to_state" => {"$in" => coverage_statuses},
        "transition_at" => {
           "$gte" => start_time,
           "$lt" => end_time
        }
      }
    },
    "households.hbx_enrollments.kind" => {"$nin" => enrollment_kinds}
  }},
  {"$group" => {"_id" => "$households.hbx_enrollments.hbx_id"}}
])

terms = Family.collection.aggregate([
  {"$match" => {
    "households.hbx_enrollments.workflow_state_transitions" => {
      "$elemMatch" => {
        "to_state" => {"$in" => ["coverage_terminated","coverage_canceled"]},
        "transition_at" => {
           "$gte" => start_time,
           "$lt" => end_time
        }
      }
    }
  }},
  {"$unwind" => "$households"},
  {"$unwind" => "$households.hbx_enrollments"},
  {"$match" => {
    "households.hbx_enrollments.workflow_state_transitions" => {
      "$elemMatch" => {
        "to_state" => {"$in" => ["coverage_terminated","coverage_canceled"]},
        "transition_at" => {
           "$gte" => start_time,
           "$lt" => end_time
        }
      }
    },
    "households.hbx_enrollments.kind" => {"$nin" => enrollment_kinds}
  }},
  {"$group" => {"_id" => "$households.hbx_enrollments.hbx_id"}}
])

puts purchases.count
puts terms.count

purchase_event = "acapi.info.events.hbx_enrollment.coverage_selected"
purchases.each do |rec|
  pol_id = rec["_id"]
  Rails.logger.info "-----publishing #{pol_id}"
  IVLEnrollmentsPublisher.publish_action(purchase_event, pol_id, "urn:openhbx:terms:v1:enrollment#initial")
end

term_event = "acapi.info.events.hbx_enrollment.terminated"
terms.each do |rec|
  pol_id = rec["_id"]
  Rails.logger.info "-----publishing #{pol_id}"
  ShopEnrollmentsPublisher.publish_action(term_event, pol_id, "urn:openhbx:terms:v1:enrollment#terminate_enrollment")
end