module Queries
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
end