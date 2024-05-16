# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Transfers
      module MedicaidGateway
        # Publish class will build event and publish the payload
        class PublishTransferResponse
          include Dry::Monads[:do, :result]
          include EventSource::Command

          def call(payload)
            event = yield build_event(payload)
            result = yield publish(event)

            Success(result)
          end

          private

          def build_event(payload)
            event('events.iap.transfers.transferred_account_response', attributes: payload)
          end

          def publish(event)
            event.publish

            Success("Returned transfer response to Medicaid Gateway")
          end
        end
      end
    end
  end
end