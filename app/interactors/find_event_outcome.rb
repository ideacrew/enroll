# frozen_string_literal: true

# FindEventOutcome is an interactor that determines the outcome of an event based on the following:
# 1. Is the service area changed?
# 2. Is the product offered in the new service area?
# 3. Is the enrollment valid in the new rating area?
class FindEventOutcome
  include Interactor

  def call
    context.event_outcome = event_outcome
  end

  private

  def event_outcome
    return "rating_area_changed" if (is_service_area_changed && product_offered_in_new_service_area && enrollment_valid_in_new_rating_area) ||
                                    (is_service_area_changed == false && enrollment_valid_in_new_rating_area)

    return "service_area_changed" if is_service_area_changed && [product_offered_in_new_service_area, enrollment_valid_in_new_rating_area].any?(false)

    return "no_change" if is_service_area_changed == false && enrollment_valid_in_new_rating_area == false
  end

  def is_service_area_changed
    context.is_service_area_changed
  end

  def product_offered_in_new_service_area
    context.product_offered_in_new_service_area
  end

  def enrollment_valid_in_new_rating_area
    context.enrollment_valid_in_new_rating_area
  end
end
