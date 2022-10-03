# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Applications
      module MedicaidGateway
        # Publish class will build event and publish the payload
        # Currently, this Operations works for following events:
        #   1. determine_eligibility for publishing the payload to get determination from MedicaidGateway
        #      The event determine_eligibility is for integration b/w Enroll & MedicaidGateway
        #   2. application_renewal_request_created for publishing the payload to generate renewal draft application
        #      The event application_renewal_request_created is for EA's internal use
        #   3. submit_renewal_draft for publishing the payload to submit/renew renewal draft application
        #      The event submit_renewal_draft is for EA's internal use
        class PublishApplication
          include Dry::Monads[:result, :do, :try]
          include EventSource::Command

          # Update this constant with new events that are added/registered in ::Publishers::ApplicationPublisher
          REGISTERED_EVENTS = %w[determine_eligibility application_renewal_request_created submit_renewal_draft].freeze

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
            if @event_name == 'application_renewal_request_created'
              event("events.iap.applications.renewals.#{@event_name}", attributes: payload)
            else
              event("events.iap.applications.#{@event_name}", attributes: payload)
            end
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