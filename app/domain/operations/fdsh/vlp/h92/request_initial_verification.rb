# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Fdsh
    module Vlp
      module H92
        # vlp initial request
        class RequestInitialVerification
          # primary request from fdsh gateway

          include Dry::Monads[:result, :do, :try]
          include Acapi::Notifiers

          # @param [ Hash ] params Applicant Attributes
          # @return [ BenefitMarkets::Entities::Applicant ] applicant Applicant
          def call(params)
            payload_param = yield construct_payload_hash(params)
            payload_value = yield validate_payload(payload_param)
            payload_entity = yield create_payload_entity(payload_value)
            payload = yield publish(payload_entity)

            Success(payload)
          end

          private

          def construct_payload_hash(person)
            if person.is_a?(::Person)
              Operations::Transformers::PersonTo::Cv3Person.new.call(person)
            else
              Failure("Invalid Person Object #{person}")
            end
          end

          def validate_payload(value)
            result = AcaEntities::Contracts::People::PersonContract.new.call(value)
            if result.success?
              Success(result)
            else
              hbx_id = value[:hbx_id]
              Failure("Person with hbx_id #{hbx_id} is not valid due to #{result.errors.to_h}.")
            end
          end

          def create_payload_entity(value)
            Success(AcaEntities::People::Person.new(value.to_h))
          end

          def publish(payload)
            Operations::Fdsh::Vlp::H92::PublishInitialVerificationRequest.new.call(payload)
          end
        end
      end
    end
  end
end
