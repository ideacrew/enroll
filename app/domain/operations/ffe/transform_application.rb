# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
# require 'aca_entities'
require 'aca_entities/ffe/operations/process_mcr_application'
require 'aca_entities/ffe/operations/mcr_to/family'

module Operations
  module Ffe
    # operation to transform mcr data to enroll format
    class TransformApplication
      include Dry::Monads[:do, :result, :try]

      # @param [ Hash] mcr_application_payload to transform
      # @return [ Hash ] family_hash
      # api public
      def call(app_payload)
        family_params = yield transform(app_payload)
        validated_params = yield validate(family_params)

        Success(validated_params)
      end

      private

      def transform(app_payload)
        result = AcaEntities::Ffe::Operations::ProcessMcrApplication.new(source_hash: app_payload, worker: :single).call

        if result.success?
          result
        elsif result.failure.class.instance_of?(Dry::Validation::Result)
          Failure(errors: result.failure.errors(full: true).to_h)
        else
          Failure(errors: result.failure)
        end
      end

      def validate(family_params)
        # TODO: write new entoties and contracts for family hash validation
        Success(family_params)
      end
    end
  end
end
