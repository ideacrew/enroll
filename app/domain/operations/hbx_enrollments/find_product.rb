# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module HbxEnrollments
    # FindProduct
    class FindProduct
      include Dry::Monads[:do, :result]

      # input: {"hios_id"=>"45142NV0010001-04", "benefit_market_kind"=>"aca_individual", "kind"=>"health"}, year: 2019/2020
      def call(query_hash, year)
        q_hash   = yield validate(query_hash, year)
        product  = yield find_product(q_hash, year)

        Success(product)
      end

      private

      def validate(query_hash, _year)
        if query_hash.is_a?(Hash)
        # TODO: Add validation for year
          Success(query_hash)
        else
          Failure('Expected input to be in Hash format')
        end
      end

      def find_product(q_hash, year)
        product = ::BenefitMarkets::Products::Product.where(q_hash).select {|p| p.active_year == year.to_i}.first
        if product.present?
          Success(product)
        else
          Failure("Unable to find Product for #{q_hash}--#{year}.")
        end
      rescue StandardError
        Failure("Exception: Unable to find Product for #{q_hash}--#{year}.")
      end
    end
  end
end
