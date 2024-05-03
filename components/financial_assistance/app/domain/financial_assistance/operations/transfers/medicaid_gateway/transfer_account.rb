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
            @payload = payload
            event = yield build_event(payload)
            result = yield publish(event)

            Success(result)
          end

          private

          def build_event(payload)
            payload[:service] = FinancialAssistanceRegistry[:transfer_service].item
            event('events.iap.transfers.transfer_account', attributes: payload)
          end

          def publish(event)
            Rails.logger.info("publishing the payload to medicaid_gateway to be transferred out for application: #{@payload[:family][:hbx_id]}")
            event.publish

            Success("Successfully published the payload to medicaid_gateway to be transferred out to ACES")
          end
        end
      end
    end
  end
end