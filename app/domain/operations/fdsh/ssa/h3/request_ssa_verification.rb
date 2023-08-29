# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Fdsh
    module Ssa
      module H3
        # vlp initial request
        class RequestSsaVerification
          # primary request from fdsh gateway

          include Dry::Monads[:result, :do, :try]
          include EventSource::Command

          # @param [ Hash ] params Applicant Attributes
          # @return [ BenefitMarkets::Entities::Applicant ] applicant Applicant
          def call(person)
            payload_entity = yield build_and_validate_payload_entity(person)
            event  = yield build_event(payload_entity.to_h)
            result = yield publish(event)

            Success(result)
          end

          private

          def build_and_validate_payload_entity(person)
            Operations::Fdsh::BuildAndValidatePersonPayload.new.call(person, :ssa)
          end

          def build_event(payload)
            event('events.fdsh.ssa.h3.ssa_verification_requested', attributes: payload, headers: { correlation_id: payload[:hbx_id], payload_type: EnrollRegistry[:ssa_h3].setting(:payload_type).item })
          end

          def publish(event)
            event.publish

            Success("Successfully published the payload to fdsh_gateway")
          end
        end
      end
    end
  end
end
