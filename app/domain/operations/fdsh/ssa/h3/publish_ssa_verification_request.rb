# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Fdsh
    module Ssa
      module H3
        # Publish class will build event and publish the payload
        class PublishSsaVerificationRequest
          send(:include, Dry::Monads[:result, :do, :try])
          include EventSource::Command

          def call(payload)
            event  = yield build_event(payload)
            result = yield publish(event)

            Success(result)
          end

          private

          def build_event(payload)
            event('events.fdsh.ssa.h3.ssa_verification_requested', attributes: payload.to_h, headers: { correlation_id: payload.to_h[:hbx_id] })
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
