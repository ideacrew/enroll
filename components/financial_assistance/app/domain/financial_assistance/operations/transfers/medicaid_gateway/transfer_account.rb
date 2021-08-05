# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Transfers
      module MedicaidGateway
        # Publish class will build event and publish the payload
        class TransferAccount
          send(:include, Dry::Monads[:result, :do, :try])
          include EventSource::Command

          def call(payload)
            event = yield build_event(payload)
            result = yield publish(event)

            Success(result)
          end

          private

          def build_event(payload)
            result = event('events.iap.transfers.transfer_account', attributes: payload)
            puts "IAP Transfer Publisher to enroll, event_key: transfer_account, attributes: #{payload.to_h}, result: #{result}"
            result
          end

          def publish(event)
            event.publish

            Success("Successfully published the payload to medicaid_gateway to be transferred out to ACES")
          end
        end
      end
    end
  end
end