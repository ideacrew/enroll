# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Applications
      module Esi
        module H14
          # publising request to H14 hub service for esi mec determination
          class PublishEsiMecRequest
            include Dry::Monads[:do, :result]
            include EventSource::Command

            def call(payload, application_id)
              event = yield build_event(payload, application_id)
              result = yield publish(event)

              Success(result)
            end

            private

            def build_event(payload, application_id)
              event('events.fdsh.esi.h14.determine_esi_mec_eligibility', attributes: payload.to_h, headers: { correlation_id: application_id })
            end

            def publish(event)
              event.publish

              Success("Successfully published the payload to fdsh for esi mec determination")
            end
          end
        end
      end
    end
  end
end