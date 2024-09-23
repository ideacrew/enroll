# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Determinations
    # Create Determination
    class Create
      include Dry::Monads[:do, :result]

      # @param [Hash] opts Options to create determination entity
      # @return [Dry::Monad] result
      def call(params)
        values = yield validate(params)
        determination = yield create(values)

        Success(determination)
      end

      private

      def validate(params)
        contract_result = AcaEntities::Eligibilities::Contracts::DeterminationContract.new.call(params)
        contract_result.success? ? Success(contract_result.to_h) : Failure(contract_result.errors)
      end

      def create(values)
        Success(AcaEntities::Eligibilities::Determination.new(values))
      end
    end
  end
end
