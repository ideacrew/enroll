# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module EligibilityItems
    # Create eligibility item domain entity
    class Create
      include Dry::Monads[:do, :result]

      # @param [Hash] opts Options to create eligibility item

      # @return [Dry::Monad] result
      def call(params)
        values = yield validate(params)
        eligibility_item = yield create(values)

        Success(eligibility_item)
      end

      private

      def validate(params)
        contract_result =
          AcaEntities::Eligibilities::Contracts::EligibilityItemContract.new
                                                                        .call(params)
        if contract_result.success?
          Success(contract_result.to_h)
        else
          Failure(contract_result.errors)
        end
      end

      def create(values)
        eligibility_item = AcaEntities::Eligibilities::EligibilityItem.new(values)

        Success(eligibility_item)
      end
    end
  end
end
