# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Eligible
    # Create Eligibility
    class CreateStateHistory
      include Dry::Monads[:do, :result]

      # @param [Hash] opts Options to build evidence
      # @option opts [GlobalID] :subject required
      # @option opts [AcaEntities::Elgibilities::EligibilityItem] :eligibility_item required
      # @option opts [AcaEntities::Elgibilities::EvidenceItem] :evidence_item required
      # @option opts [Date] :effective_date required
      # @return [Dry::Monad] result
      def call(params)
        values = yield validate(params)
        eligibility = yield create(values)

        Success(eligibility)
      end

      private

      def validate(params)
        contract_result = AcaEntities::Eligible::StateHistoryContract.new.call(params)
        contract_result.success? ? Success(contract_result.to_h) : contract_result
      end

      def create(values)
        Success(AcaEntities::Eligible::StateHistory.new(values))
      end
    end
  end
end
