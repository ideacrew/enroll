# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module HbxEnrollments
    # FindIssuerProfile
    class FindIssuerProfile
      include Dry::Monads[:do, :result]

      def call(query_hash)
        q_hash = yield validate(query_hash)
        product  = yield find_product(q_hash)

        Success(product)
      end

      private

      def validate(query_hash)
        if query_hash.is_a?(Hash)
          Success(query_hash)
        else
          Failure('expected input to be in Hash format')
        end
      end

      def find_product(q_hash)
        # TODO: fix this
        product = ::BenefitMarkets::Products::Product.where(q_hash).first
        if product.present?
          Success(product)
        else
          Failure('expected input to be in Hash format')
        end
      rescue StandardError
        Failure("Unable to find Product for #{q_hash}.")
      end
    end
  end
end
