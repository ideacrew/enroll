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

            def call(payload)
              event  = yield build_event(payload)
              result = yield publish(event)

              Success(result)
            end

            private

            def build_event(payload)
              verification_response = payload.dig(:InitialVerificationResponseSet, :InitialVerificationIndividualResponses).first
              case_number = verification_response.dig(:InitialVerificationIndividualResponseSet, :CaseNumber)
              event('events.fdsh.close_case_request', headers: { case_number: case_number })
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
