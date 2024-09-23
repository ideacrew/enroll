# frozen_string_literal: true

module Operations
  module Products
    # This class is to fetch silver products for giving rating & service area ids.
    class FetchSilverProducts
      include Dry::Monads[:do, :result]

      # @param [Date] effective_date
      # @param [Address] address
      def call(params)
        values            = yield validate(params)
        rating_area       = yield find_rating_area(values[:effective_date], values[:address])
        service_areas     = yield find_service_areas(values[:effective_date], values[:address])
        query             = yield query_criteria(rating_area.id, service_areas.map(&:id), values[:effective_date])
        cache_key         = yield construct_cache_key(rating_area.id, service_areas.map(&:id), values[:effective_date])
        products          = yield fetch_products(cache_key, query, values)
        payload           = yield construct_payload(products, rating_area.id, rating_area.exchange_provided_code)

        Success(payload)
      end

      private

      def validate(params)
        return Failure('Missing Address') if params[:address].blank?
        return Failure('Missing Effective Date') if params[:effective_date].blank?
        Success(params)
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
                  :metal_level_kind.in => [:silver, :dental],
                  :'premium_tables.rating_area_id' => rating_area_id,
                  :service_area_id.in => service_area_ids,
                  :'application_period.min'.lte => effective_date,
                  :'application_period.max'.gte => effective_date,
                  :benefit_market_kind => :aca_individual
                })
      end

      def construct_cache_key(rating_area_id, service_area_ids, effective_date)
        Success({
                  :metal_level_kinds => [:silver, :dental],
                  :rating_area_id => rating_area_id.to_s,
                  :service_area_ids => service_area_ids.map(&:to_s),
                  :active_year => effective_date.year,
                  :benefit_market_kind => :aca_individual
                })
      end

      def fetch_products(cache_key, query_criteria, values)
        products = Rails.cache.fetch(cache_key.to_json, expire_in: 12.hours) do
          BenefitMarkets::Products::Product.where(query_criteria).to_a
        end

        if products.present?
          Success(products)
        else
          Failure("Could Not find any Products for the given criteria - effective_date: #{values[:effective_date]}, county: #{values[:address].county}, zip: #{values[:address].zip}")
        end
      end

      def construct_payload(products, rating_area_id, rating_area_exchange_provided_code)
        Success({products: products, rating_area_id: rating_area_id,
                 rating_area_exchange_provided_code: rating_area_exchange_provided_code})
      end
    end
  end
end
