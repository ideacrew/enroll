# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Applications
      module AptcCsrCreditEligibilities
        module Renewals
          # Publish class will build event and publish the renewal payload
          class PublishRenewalRequest
            include Dry::Monads[:do, :result]
            include EventSource::Command

            REGISTERED_EVENTS = %w[renewal.requested renewed determination_submission.requested determination_requested determination_added notice.determined_uqhp_eligible notice.determined_mixed_determination
                                   notice.determined_magi_medicaid_eligible notice.determined_totally_ineligible notice.determined_medicaid_chip_eligible notice.determined_aptc_eligible].freeze

            def call(params)
              payload = yield validate_input_params(params)
              event = yield build_event(payload)
              result = yield publish(event)

              Success(result)
            end

            private

            def validate_input_params(params)
              return Failure('Missing payload key') unless params.key?(:payload)
              return Failure('Missing event_name key') unless params.key?(:event_name)
              return Failure("Invalid value: #{params[:payload]} for key payload, must be a Hash object") if params[:payload].nil? || !params[:payload].is_a?(Hash)
              return Failure("Invalid value: #{params[:event_name]} for key event_name, must be an String") if params[:event_name].nil? || !params[:event_name].is_a?(String)
              return Failure("Invalid event_name: #{params[:event_name]} for key event_name, must be one of #{REGISTERED_EVENTS}") if REGISTERED_EVENTS.exclude?(params[:event_name])

              @event_name = params[:event_name]

              Success(params[:payload])
            end

            def build_event(payload)
              event("events.applications.aptc_csr_credits.renewals.#{@event_name}", attributes: payload)
            end

            def publish(event)
              event.publish

              Success("Successfully published the payload for event: #{@event_name}")
            end
          end
        end
      end
    end
  end
end