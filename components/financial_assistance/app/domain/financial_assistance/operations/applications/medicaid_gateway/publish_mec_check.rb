# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Applications
      module MedicaidGateway
        # Publish class will build event and publish the payload for a MEC check
        class PublishMecCheck
          send(:include, Dry::Monads[:result, :do, :try])
          include EventSource::Command

          def call(payload)
            event = yield build_event(payload)
            result = yield publish(event)

            Success(result)
          end

          private

          def build_event(payload)            
            event('events.iap.mec_check.mec_check_requested', attributes: payload)
          end

          def publish(event)
            event.publish

            Success("Successfully published the payload to medicaid_gateway to be transferred out to ACES for MEC check")
          end
        end
      end
    end
  end
end