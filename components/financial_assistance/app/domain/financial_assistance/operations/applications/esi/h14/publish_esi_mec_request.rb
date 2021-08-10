# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Applications
      module Esi
        module H14
          class PublishEsiMecRequest
            send(:include, Dry::Monads[:result, :do, :try])
            include EventSource::Command

            def call(payload)
              event = yield build_event(payload)
              result = yield publish(event)

              Success(result)
            end

            private

            def build_event(payload)
              event('events.iap.esi.h14.determine_esi_mec_eligibility', attributes: payload)
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