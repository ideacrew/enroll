# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module IvlOsseEligibility
    # Operation to support evidence creation
    class CreateAdminAttestedEvidence
      send(:include, Dry::Monads[:result, :do])

      # @param [ Hash ] params AdminAttestedEvidence Attributes
      # @return [ IvlOsseEligibility::AdminAttestedEvidence ]
      def call(params)
        values = yield validate(params)
        product = yield create(values)

        Success(product)
      end

      private

      def validate(params)
        result =
          AcaEntities::People::IvlOsseEligibility::AdminAttestedEvidenceContract.new.call(
            params
          )

        if result.success?
          Success(result.to_h)
        else
          result
        end
      end

      def create(values)
        evidence_entity = AcaEntities::People::IvlOsseEligibility::AdminAttestedEvidence.new(values)

        Success(evidence_entity)
      end
    end
  end
end