# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Eligibilities
    # Create Eligibility
    class Create
      send(:include, Dry::Monads[:result, :do])

      # @param [Hash] opts Options to create eligibility entity
      # @return [Dry::Monad] result
      def call(params)
        values = yield validate(params)
        eligibility = yield create(values)

        Success(eligibility)
      end

      private

      def validate(params)
        contract_result = AcaEntities::Eligibilities::Osse::Contracts::EligibilityContract.new.call(params)
        contract_result.success? ? Success(contract_result.to_h) : Failure(contract_result.errors)
      end

      def create(values)
        Success(AcaEntities::Eligibilities::Osse::Eligibility.new(values))
      end
    end
  end
end
