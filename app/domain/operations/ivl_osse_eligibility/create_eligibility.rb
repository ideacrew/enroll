# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module IvlOsseEligibility
    # Operation to support eligibility creation
    class CreateEligibility
      send(:include, Dry::Monads[:result, :do])

      # @param [ Hash ] params IvlOsseEligibility::Eligibility Attributes
      # @return [ People::IvlOsseEligibility::Eligibility ]
      def call(params)
        values = yield validate(params)
        product = yield create(values)

        Success(product)
      end

      private

      def validate(params)
        result =
          AcaEntities::People::IvlOsseEligibility::EligibilityContract.new.call(
            params
          )

        if result.success?
          Success(result.to_h)
        else
          result
        end
      end

      def create(values)
        eligibility_entity = AcaEntities::People::IvlOsseEligibility::Eligibility.new(values)

        Success(eligibility_entity)
      end
    end
  end
end
