# frozen_string_literal: true

module HbxEnrollments
# FindEnrollmentEventOutcome is an interactor that determines the outcome of an event based on the following:
# 1. Is the service area changed?
# 2. Is the product offered in the new service area?
# 3. Is the enrollment valid in the new rating area?
  class FindEnrollmentEventOutcome
    include Interactor

    def call
      context.event_outcome = event_outcome
    end

    private

    def event_outcome
      return "rating_area_changed" if (is_service_area_changed && product_offered_in_new_service_area && is_rating_area_changed) ||
                                      (is_service_area_changed == false && is_rating_area_changed)

      return "service_area_changed" if is_service_area_changed && [product_offered_in_new_service_area, is_rating_area_changed].any?(false)

      return "no_change" if is_service_area_changed == false && is_rating_area_changed == false
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
  end
end
