# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Fdsh
    module Ridp
      # ridp Secondary request
      class RequestSecondaryDetermination
        # Secondary request from fdsh gateway

        include Dry::Monads[:result, :do, :try]
        include Acapi::Notifiers

        # @param [ Hash ] params Applicant Attributes
        # @return [ BenefitMarkets::Entities::Applicant ] applicant Applicant
        def call(family, InteractiveVerification)
          payload_param = yield construct_payload_hash(params)
          payload_value = yield validate_payload(payload_param)
          payload_entity = yield create_payload_entity(payload_value)
          payload = yield publish(payload_entity)

          Success(payload)
        end

        private

        def construct_payload_hash(family)
          if family.is_a?(Family)
            Operations::Transformers::PersonTo::Cv3Person.new.call(family)
          else
            Failure("Invalid Family Object #{family}")
          end
        end

        def validate_payload(value)
          result = AcaEntities::Contracts::People::PersonContract.new.call(value)
          result.success? ? Success(result) : Failure("Person with hbx_id #{hbx_id} is not valid due to #{result.errors}.")
        end

        def create_payload_entity(value)
          Success(AcaEntities::People::Person.new(value.to_h))
        end

        def publish(payload)
          Operations::Fdsh::Ridp::PublishSecondaryRequest.new.call(payload)
        end
      end
    end
  end
end
