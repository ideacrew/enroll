# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Fdsh
    module Vlp
      module Rx142
        module CloseCase
          # vlp close case request
          class PublishCloseCaseRequest

            include Dry::Monads[:result, :do, :try]
            include EventSource::Command

            def call(payload, correlation_id)
              event  = yield build_event(payload, correlation_id)
              result = yield publish(event)

              Success(result)
            end

            private

            def build_event(payload, correlation_id)
              verification_response = payload.dig(:InitialVerificationResponseSet, :InitialVerificationIndividualResponses).first
              case_number = verification_response.dig(:InitialVerificationIndividualResponseSet, :CaseNumber)

              person = Person.where(hbx_id: correlation_id).first
              cv3_person = Operations::Fdsh::BuildAndValidatePersonPayload.new.call(person, :dhs)

              event('events.fdsh.close_case_request.close_case_requested', attributes: cv3_person, headers: { case_number: case_number, correlation_id: correlation_id })
            end

            def publish(event)
              event.publish
              Success("Successfully published the close case request payload to fdsh_gateway")
            end

          end
        end
      end
    end
  end
end
