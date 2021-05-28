module Operations
  module Products
    # This class is to load county zip combinations.
    class MemberPremium
      include Dry::Transaction::Operation

      def call(hra_object)
        tenant = Tenants::Tenant.find_by_key(hra_object.tenant)
        
        if tenant.use_age_ratings == "age_rated"
          hra_object.age = ::Operations::AgeOn.new.call(hra_object).success
        end

        if ['zipcode', 'county'].include?(tenant.geographic_rating_area_model)
          rating_area_result = ::Locations::Operations::SearchForRatingArea.new.call(hra_object)
          if rating_area_result.success?
            hra_object.rating_area_id = rating_area_result.success.id.to_s
          else
            return Failure(hra_object)
          end
        end

        if ['zipcode', 'county'].include?(tenant.geographic_rating_area_model)
          service_areas_result = ::Locations::Operations::SearchForServiceArea.new.call(hra_object)
          if service_areas_result.success?
            hra_object.service_area_ids = service_areas_result.success.pluck(:id).map(&:to_s)
          else
            return Failure(hra_object)
          end
        end

        fetch_products_result = ::Products::Operations::FetchProducts.new.call(hra_object)
        return Failure(hra_object) if fetch_products_result.failure?

        lcrp_result_array = ::Products::Operations::LowCostReferencePlanCost.new.call({products: fetch_products_result.success, hra_object: hra_object})
        if lcrp_result_array.success?
          Success(lcrp_result_array.success)
        else
          Failure(hra_object)
        end
      end
    end
  end
end
