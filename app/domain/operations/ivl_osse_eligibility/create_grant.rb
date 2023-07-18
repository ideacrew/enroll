# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module IvlOsseEligibility
    # Operation to support grant creation
    class CreateGrant
      send(:include, Dry::Monads[:result, :do])

      # @param [ Hash ] params Grant Attributes
      # @return [ IvlOsseEligibility::Grant ]
      def call(params)
        values = yield validate(params)
        product = yield create(values)

        Success(product)
      end

      private

      def validate(params)
        result =
          AcaEntities::People::IvlOsseEligibility::GrantContract.new.call(
            params
          )

        if result.success?
          Success(result.to_h)
        else
          result
        end
      end

      def create(values)
        grant_entity = AcaEntities::People::IvlOsseEligibility::Grant.new(values)

        Success(grant_entity)
      end
    end
  end
end
