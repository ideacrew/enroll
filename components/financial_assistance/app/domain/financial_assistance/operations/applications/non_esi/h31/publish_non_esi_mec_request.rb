# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Applications
      module NonEsi
        module H31
          # publising request to H14 hub service for esi mec determination
          class PublishNonEsiMecRequest
            include Dry::Monads[:do, :result]
            include EventSource::Command

            def call(payload, application_id)
              event = yield build_event(payload, application_id)
              result = yield publish(event)

              Success(result)
            end

            private

            def build_event(payload, application_id)
              event('events.fdsh.non_esi.h31.determine_non_esi_mec_eligibility', attributes: payload.to_h, headers: { correlation_id: application_id })
            end

            def publish(event)
              event.publish

              Success("Successfully published the payload to fdsh for non esi mec determination")
            end
          end
        end
      end
    end
  end
end