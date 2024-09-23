# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module BenchmarkProducts
    # This class takes BenchmarkProducts params as input and returns the BenchmarkProductsModel entity
    class Initialize
      include Dry::Monads[:do, :result]

      def call(params)
        validated_params  = yield validate_params(params)
        benchmark_product = yield initialize_application(validated_params)

        Success(benchmark_product)
      end

      private

      def validate_params(params)
        result = ::Validators::BenchmarkProducts::BenchmarkProductContract.new.call(params)

        if result.success?
          Success(result.to_h)
        else
          Failure(result)
        end
      end

      def initialize_application(validated_params)
        Success(::Entities::BenchmarkProducts::BenchmarkProduct.new(validated_params))
      end
    end
  end
end
