require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Products
    # This class is to load county zip combinations.
    class Fetch
      send(:include, Dry::Monads[:result, :do])
      send(:include, Dry::Monads[:try])
      # include Dry::Transaction::Operation

      # @param [Date] effective_date
      # @param [ServiceArea] service_areas
      # @param [RatingArea] rating_area
      # @param [Integer] age
      def call(params)
        values   = yield validate(params)
        query    = yield query_criteria(values)
        products = yield fetch_products(values, query)

        Success(products)
      end

      private

      def validate(params)
        Success(params)
      end

      def query_criteria(params)
        geographic_rating_area_model = EnrollRegistry[:enroll_app].setting(:geographic_rating_area_model).item

        query_criteria = {
          :premium_tables.exists => true,
          :"premium_tables.premium_tuples".exists => true,
          :"premium_tables.premium_tuples.age" => params[:age],
          :"premium_tables.effective_period.min".lte => params[:effective_date],
          :"premium_tables.effective_period.max".gte => params[:effective_date]
        }

        if geographic_rating_area_model == 'zipcode'
          query_criteria.merge!(
            {
              :"service_area_id".in => params[:service_areas].map(&:id),
              :"premium_tables.rating_area_id" => BSON::ObjectId.from_string(params[:rating_area].id)
            }
          )
        end

        if geographic_rating_area_model == 'county'
          query_criteria.merge!({:"service_area_id".in => params[:service_areas].map(&:id)})
        end

        Success(query_criteria)
      end

      def fetch_products(values, query_criteria)
        products = BenefitMarkets::Products::Product.where(query_criteria)
        if products.present?
          Success(products)
        else
          Failure("Could Not find any Products for the given criteria - effective_date: #{values[:effective_date]}, county: #{values[:address].county}, zip: #{values[:address].zip}")
        end
      end
    end
  end
end
