# frozen_string_literal: true

module Insured
  module Factories
    class ProductFactory

      attr_accessor :product_id, :product, :issuer_id

      def initialize(product_id)
        self.product_id = product_id
      end

      def self.find(product_id)
        new(product_id).product
      end

      def product
        self.product = ::BenefitMarkets::Products::HealthProducts::HealthProduct.find(BSON::ObjectId.from_string(product_id))
      end
    end
  end
end
