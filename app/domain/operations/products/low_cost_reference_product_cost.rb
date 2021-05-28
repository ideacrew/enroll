module Operations
  module Products
    # This class is to load county zip combinations.
    class LowCostReferenceProductCost
      send(:include, Dry::Monads[:result, :do])
      send(:include, Dry::Monads[:try])


      # @param [Date] effective_date
      # @param [Family] family

      def call(params)
        values            = yield validate(params)
        address           = yield find_address(values[:family])
        rating_area       = yield find_rating_area(values[:effective_date], address)
        service_areas     = yield find_service_areas(values[:effective_date], address)
        products          = yield fetch_products(values[:effective_date], rating_area, service_areas)
        reference_product = yield find_low_cost_reference_product(products, values[:effective_date], rating_area)
      end

      private

      def validate(params)
        Success params
      end

      def find_address(family)
        consumer_role = family&.primary_person&.consumer_role

        if consumer_role
          Success(consumer_role.rating_address)
        else
          Failure("No primary consumer role found for the given family: #{family.id}")
        end
      end

      def find_rating_area(effective_date, address)
        rating_area = ::BenefitMarkets::Locations::RatingArea.rating_area_for(address, during: effective_date)

        if rating_area.present?
          Success(rating_area)
        else
          Failure("Rating Area not found for effective_date: #{effective_date}, county: #{address.county}, zip: #{address.zip}")
        end
      end

      def find_service_areas(effective_date, address)
        service_areas = ::BenefitMarkets::Locations::ServiceArea.service_areas_for(address, during: effective_date)
        
        if service_areas.present?
          Success(service_areas)
        else
          Failure("Service Areas not found for effective_date: #{effective_date}, county: #{address.county}, zip: #{address.zip}")
        end        
      end

      def fetch_products(effective_date, rating_area, service_areas)
        ::Operations::Products::Fetch.new.call(effective_date: effective_date, rating_area: rating_area, service_areas: service_areas)
      end

      def find_low_cost_reference_product(products, effective_date, rating_area)
        geographic_rating_area_model = EnrollRegistry[:enroll_app].setting(:geographic_rating_area_model).item
        # geographic_rating_area_model = 'county'
        use_age_ratings = 'non_age_rated'
        member_premiums = products.inject([]) do |premiums_array, product|
          begin
            premium_tables =
              if geographic_rating_area_model == 'single'
                product.premium_tables.effective_period_cover(effective_date)
              else
                product.premium_tables.where(:rating_area_id => rating_area.id).effective_period_cover(effective_date)
              end

            premium_tables.each do |premium_table|
              if use_age_ratings == "age_rated"
                user_age = 20 # TODO: FIX ME hra_object.age
                age = ::Operations::AgeLookup.new.call(user_age).success
                pt = premium_table.premium_tuples.where(age: age).first
                premiums_array << [pt.cost, product.find_carrier_info, product.hios_id, product.title]
              elsif use_age_ratings == "non_age_rated"
                pt = premium_table.premium_tuples.first
                premiums_array << [pt.cost, product.find_carrier_info, product.hios_id, product.title]
              end
              premiums_array
            end

            premiums_array
          rescue
            premiums_array
          end
          premiums_array.compact
        end

        if member_premiums.empty?
          Failure('Could Not find any member premiums for the given data')
        else
          final_premium_set = member_premiums.uniq(&:first).sort_by{|mp| mp.first}
          cost = final_premium_set.second || final_premium_set.first
          Success(cost)
        end
      end
    end
  end
end
