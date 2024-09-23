# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Fdsh
    module Ridp
      # ridp Secondary request
      class RequestSecondaryDetermination
        # Secondary request from fdsh gateway

        include Dry::Monads[:do, :result]
        include Acapi::Notifiers

        def call(family, interactive_verification)
          family_hash = yield construct_payload_hash(family)
          attestation_hash = yield construct_attestation_payload(interactive_verification)
          payload_with_attestation = yield merge_attestation_to_user(family_hash, attestation_hash)
          payload_value = yield validate_payload(payload_with_attestation)
          payload_entity = yield create_payload_entity(payload_value)
          payload = yield publish(payload_entity, interactive_verification)

          Success(payload)
        end

        private

        def construct_payload_hash(family)
          if family.is_a?(::Family)
            Operations::Transformers::FamilyTo::Cv3Family.new.call(family)
          else
            Failure("Invalid Family Object #{family}")
          end
        end

        def construct_attestation_payload(interactive_verification)
          Operations::Transformers::InteractiveVerificationTo::Attestation.new.call(interactive_verification)
        end

        def merge_attestation_to_user(family, attestations)
          family[:family_members][0][:person][:user].merge!({attestations: [attestations]})

          Success(family)
        end

        def validate_payload(value)
          result = AcaEntities::Contracts::Families::FamilyContract.new.call(value)
          if result.success?
            Success(result)
          else
            hbx_id = value[:family_members].detect{|a| a[:is_primary_applicant] == true}[:person][:hbx_id]
            Failure("Person with hbx_id #{hbx_id} is not valid due to #{result.failure.errors.to_h}.")
          end
        end

        def create_payload_entity(value)
          Success(AcaEntities::Families::Family.new(value.to_h))
        end

        def publish(payload, interactive_verification)
          session_id = interactive_verification&.session_id
          transmission_id = interactive_verification&.transaction_id
          Operations::Fdsh::Ridp::PublishSecondaryRequest.new.call(payload, session_id, transmission_id)
        end
      end
    end
  end
end
