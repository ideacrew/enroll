# frozen_string_literal: true

module Operations
  module Products
    # This class is to fetch silver product premiums for giving rating & service area ids.
    class FetchSilverProductPremiums
      include Dry::Monads[:result, :do]

      # @param [Date] effective_date
      # @param [Family] family
      def call(params)
        values            = yield validate(params)
        address           = yield find_address(values[:family])
        rating_area       = yield find_rating_area(values[:effective_date], address)
        service_areas     = yield find_service_areas(values[:effective_date], address)
        query             = yield query_criteria(rating_area.id, service_areas.map(&:id), values[:effective_date])
        products          = yield fetch_products(query)
        product_premiums  = yield fetch_product_premiums(products, values[:family], values[:effective_date], rating_area.id)

        Success(product_premiums)
      end

      private

      def validate(params)
        return Failure('Missing Family') if params[:family].blank?
        return Failure('Missing Effective Date') if params[:effective_date].blank?
        Success(params)
      end

      def find_address(family)
        consumer_role = family&.primary_person&.consumer_role

        if consumer_role&.rating_address
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

      def query_criteria(rating_area_id, service_area_ids, effective_date)
        Success({
                  :metal_level_kind => :silver,
                  :'premium_tables.rating_area_id' => rating_area_id,
                  :service_area_id.in => service_area_ids,
                  :'application_period.min'.lte => effective_date,
                  :'application_period.max'.gte => effective_date
                })
      end

      def fetch_products(query_criteria)
        products = BenefitMarkets::Products::Product.where(query_criteria)
        if products.present?
          Success(products)
        else
          Failure("Could Not find any Products for the given criteria - effective_date: #{values[:effective_date]}, county: #{values[:address].county}, zip: #{values[:address].zip}")
        end
      end

      def fetch_product_premiums(products, family, effective_date, rating_area_id)
        member_premiums = family.family_members.inject({}) do |member_result, family_member|
          age = family_member.age_on(effective_date)
          age = ::Operations::AgeLookup.new.call(age).success if false && age_rated # Todo - Get age_rated through settings

          member_result[family_member.id.to_s] = products.inject([]) do |result, product|
            premium_table = product.premium_tables.where({
                                                           :rating_area_id => rating_area_id,
                                                           :'effective_period.min'.lte => effective_date,
                                                           :'effective_period.max'.gte => effective_date
                                                         }).first

            tuple = premium_table.premium_tuples.where(age: age).first
            result << { cost: tuple.cost, product_id: product.id } if tuple.present?
            result
          end.sort_by {|tuple_hash| tuple_hash[:cost]}

          member_result
        end
        Success(member_premiums)
      end
    end
  end
end
