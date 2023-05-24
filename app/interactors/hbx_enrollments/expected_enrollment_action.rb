# frozen_string_literal: true

module HbxEnrollments
# ExpectedEnrollmentAction is an interactor that determines the action to be taken on an enrollment based on the following:
# 1. Is the service area changed?
# 2. Is the product offered in the new service area?
# 3. Is the enrollment valid in the new rating area?
# 4. What is the event outcome?
  class ExpectedEnrollmentAction
    include Interactor

    def call
      context.action_on_enrollment = action_on_enrollment
    end

    private

    def action_on_enrollment
      return "No Action Required" if (event_outcome == "service_area_changed" && product_offered_in_new_service_area && is_rating_area_changed == false) || event_outcome == "no_change"
      return "Terminate Enrollment Effective End of the Month" if event_outcome == "service_area_changed"
      return "Generate Rerated Enrollment with same product ID" if event_outcome == "rating_area_changed"
    end

    def is_service_area_changed
      context.is_service_area_changed
    end

    def product_offered_in_new_service_area
      context.product_offered_in_new_service_area
    end

    def is_rating_area_changed
      context.is_rating_area_changed
    end

    def event_outcome
      context.event_outcome
    end
  end
end