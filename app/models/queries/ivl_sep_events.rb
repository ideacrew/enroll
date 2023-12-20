# frozen_string_literal: true

module Queries
  # Query various events during the lifetime of an IVL enrollment, based on
  # type of transition and the reasons for that transition.
  class IvlSepEvents
    attr_reader :start_time, :end_time, :excluded_enrollment_kinds

    def initialize(s_time, e_time)
      @start_time = s_time
      @end_time = e_time
      @excluded_enrollment_kinds = ["employer_sponsored", "employer_sponsored_cobra"]
    end

    def terminations_during_window
      HbxEnrollment.collection.aggregate([
      {"$match" => {
        "workflow_state_transitions" => {
          "$elemMatch" => {
            "to_state" => {"$in" => [Enrollments::WorkflowStates::COVERAGE_TERMINATED, Enrollments::WorkflowStates::COVERAGE_CANCELED]},
            "transition_at" => {
              "$gte" => start_time,
              "$lt" => end_time
            }
          }
        },
        "rating_area_id" => {"$ne" => nil},
        "kind" => {"$nin" => excluded_enrollment_kinds}
      }},
      {"$group" => {
        "_id" => "$hbx_id",
        "created_at" => { "$last" => "$created_at" }
      }},
      { "$sort" => { "created_at" => 1 } }
      ])
    end

    def selections_during_window
      active_statuses = ["coverage_selected", "auto_renewing", "renewing_coverage_selected"]
      HbxEnrollment.collection.aggregate([
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
          "kind" => {"$nin" => excluded_enrollment_kinds}
        }},
        {"$group" => {
          "_id" => "$hbx_id",
          "created_at" => { "$last" => "$created_at" },
          "enrollment_state" => {"$last" => "$aasm_state"}
        }},
        {"$project" => {
          "_id" => 1,
          "created_at" => 1,
          "enrollment_state" => "$enrollment_state"
        }},
        { "$sort" => { "created_at" => 1 } }
      ])
    end

    def has_silent_cancel?(enrollment)
      return false unless EnrollRegistry.feature_enabled?(:silent_transition_enrollment)

      enrollment.workflow_state_transitions.any? do |wst|
        (wst.to_state == 'coverage_canceled') &&
          (wst.transition_at < end_time) && (wst.transition_at >= start_time) &&
          wst.metadata_has?({"reason" => Enrollments::TerminationReasons::SUPERSEDED_SILENT})
      end
    end

    def purchase_and_cancel_in_same_window?(enrollment)
      return false unless EnrollRegistry.feature_enabled?(:silent_transition_enrollment)

      matching_cancel = enrollment.workflow_state_transitions.any? do |wst|
        (wst.to_state == Enrollments::WorkflowStates::COVERAGE_CANCELED) &&
          (wst.transition_at < end_time) && (wst.transition_at >= start_time)
      end

      matching_selection = enrollment.workflow_state_transitions.any? do |wst|
        (wst.to_state == Enrollments::WorkflowStates::COVERAGE_SELECTED) &&
          (wst.transition_at < end_time) && (wst.transition_at >= start_time)
      end

      matching_cancel && matching_selection
    end

    def skip_termination?(enrollment)
      return true unless EnrollRegistry.feature_enabled?(:silent_transition_enrollment)

      enrollment.purchase_event_published_at.blank?
    end
  end
end
