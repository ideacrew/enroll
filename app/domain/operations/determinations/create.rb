# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Determinations
    # Create Determination
    class Create
      send(:include, Dry::Monads[:result, :do])

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
        puts "::Operations::Determinations::Create params #{params}"
        puts "::Operations::Determinations::Create success #{contract_result.success?}"
        contract_result.success? ? Success(contract_result.to_h) : Failure(contract_result.errors)
      end

      def create(values)
        Success(AcaEntities::Eligibilities::Determination.new(values))
      end
    end
  end
end
