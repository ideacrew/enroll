# frozen_string_literal: true

module Operations
  module Products
    # This class is to find if IVL enrolled product is offered in service area or not.
    # Returns true if allowed, false if not allowed
    class ProductOfferedInServiceArea
      include Dry::Monads[:do, :result]

      def call(params)
        values               = yield validate(params)
        yield product_offered_in_service_area(values[:enrollment])
        Success()
      end

      private

      def validate(params)
        return Failure('Missing Enrollment') if params[:enrollment].blank?
        Success(params)
      end

      def product_offered_in_service_area(enrollment)
        return Success() if enrollment.is_shop?
        return Failure('Rating Area Is Blank') if enrollment.rating_area_id.blank?

        rating_address = (enrollment.consumer_role || enrollment.resident_role).rating_address

        return Failure('Rating Address Is Blank') if rating_address.blank?

        service_areas = ::BenefitMarkets::Locations::ServiceArea.service_areas_for(
          rating_address,
          during: enrollment.effective_on
        ).map(&:id)

        if service_areas.include?(enrollment.product.service_area_id)
          Success()
        else
          Failure('Product is NOT offered in service area')
        end
      end
    end
  end
end
