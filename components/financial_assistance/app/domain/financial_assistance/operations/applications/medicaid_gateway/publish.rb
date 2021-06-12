# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Applications
      module MedicaidGateway
        # This class will build event and publish payload
        class Publish
          send(:include, Dry::Monads[:result, :do, :try])
          include EventSource::Command

          def call(payload)
            event = yield build_event(payload)
            result = yield publish(event)

            Success(result)
          end

          private

          def build_event(params)
            event('events.iap.application.determine_eligibility', attributes: params)
          end

          def publish(event)
            event.publish
          end
        end
      end
    end
  end
end