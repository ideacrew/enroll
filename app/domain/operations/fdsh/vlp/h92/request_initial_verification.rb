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

          def call(person)
            payload_entity = yield validate_and_build_payload_entity(person)
            event  = yield build_event(payload_entity.to_h)
            result = yield publish(event)

            Success(result)
          end

          private

          def validate_and_build_payload_entity(person)
            Operations::Fdsh::ValidatePersonPayload.new.call(person, :vlp)
          end

          def build_event(payload)
            event('events.fdsh.vlp.h92.initial_verification_requested', attributes: payload, headers: { correlation_id: payload[:hbx_id] })
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
