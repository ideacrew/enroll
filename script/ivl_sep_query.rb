start_time = Time.now - 17.minutes
end_time = Time.now

class IvlEnrollmentsPublisher
  extend Acapi::Notifiers

  def self.publish_action(action_name, hbx_id, action)
    reply_to = "dc0.#{Rails.application.config.acapi.environment_name}.q.glue.enrollment_event_batch_handler"

    notify(
      action_name, {
      :reply_to => reply_to,
      :hbx_enrollment_id => hbx_id,
      :enrollment_action_uri => action
    })
  end
end


class IvlEnrollmentsQuery

  attr_reader :start_time, :end_time
  
  ENROLLMENT_KINDS = %w(employer_sponsored employer_sponsored_cobra)
  ACTIVE_STATUSES = %w(coverage_selected auto_renewing unverified renewing_coverage_selected auto_renewing_contingent renewing_contingent_selected)

  def initialize(start_time, end_time)
    @start_time = start_time
    @end_time = end_time
  end

  def purchases
    Family.collection.aggregate([
      {"$match" => {
        "households.hbx_enrollments.workflow_state_transitions" => {
          "$elemMatch" => {
            "to_state" => {"$in" => ACTIVE_STATUSES},
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
            "to_state" => {"$in" => ACTIVE_STATUSES},
            "transition_at" => {
               "$gte" => start_time,
               "$lt" => end_time
            }
          }
        },
        "households.hbx_enrollments.kind" => {"$nin" => ENROLLMENT_KINDS}
      }},
      {"$group" => {
        "_id" => "$households.hbx_enrollments.hbx_id",
        "enrollment_state" => {"$last" => "$households.hbx_enrollments.aasm_state"}
      }},
      {"$project" => {
        "_id" => 1,
        "enrollment_state" => "$enrollment_state"
      }}
    ])
  end

  def terminations
    Family.collection.aggregate([
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
        "households.hbx_enrollments.kind" => {"$nin" => ENROLLMENT_KINDS}
      }},
      {"$group" => {"_id" => "$households.hbx_enrollments.hbx_id"}}
    ])
  end
end

enrollment_query = IvlEnrollmentsQuery.new(start_time, end_time)

purchases = enrollment_query.purchases
terms = enrollment_query.terminations

purchase_event = "acapi.info.events.hbx_enrollment.coverage_selected"
purchases.each do |rec|
  pol_id = rec["_id"]
  Rails.logger.info "-----publishing #{pol_id}"

  if rec["enrollment_state"] == 'auto_renewing' || rec["enrollment_state"] == 'auto_renewing_contingent'
    IvlEnrollmentsPublisher.publish_action(purchase_event, pol_id, "urn:openhbx:terms:v1:enrollment#auto_renew")
  else
    IvlEnrollmentsPublisher.publish_action(purchase_event, pol_id, "urn:openhbx:terms:v1:enrollment#initial")
  end
end

term_event = "acapi.info.events.hbx_enrollment.terminated"
terms.each do |rec|
  pol_id = rec["_id"]
  Rails.logger.info "-----publishing #{pol_id}"
  IvlEnrollmentsPublisher.publish_action(term_event, pol_id, "urn:openhbx:terms:v1:enrollment#terminate_enrollment")
end
