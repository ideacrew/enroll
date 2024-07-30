# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Fdsh
    module Vlp
      module Rx142
        module CloseCase
          # vlp close case request
          class RequestCloseCase

            include Dry::Monads[:do, :result]
            include EventSource::Command

            def call(payload, hbx_id)
              case_number = yield get_case_number(payload)
              cv3_person = yield find_cv3_person(hbx_id)

              event  = yield build_event(cv3_person, hbx_id, case_number)
              result = yield publish(event)

              Success(result)
            end

            private

            def get_case_number(payload)
              verification_response = payload&.dig(:InitialVerificationResponseSet, :InitialVerificationIndividualResponses)&.first
              return Failure('No individual responses found in CMS response') unless verification_response

              case_number = verification_response&.dig(:InitialVerificationIndividualResponseSet, :CaseNumber)
              return Failure('No case number found in CMS response') unless case_number

              Success(case_number)
            end

            def find_cv3_person(hbx_id)
              person = Person.where(hbx_id: hbx_id).first
              return Failure("No person could be found with this hbx_id: #{hbx_id}") unless person

              Operations::Transformers::PersonTo::Cv3Person.new.call(person)
            end

            def build_event(cv3_person, hbx_id, case_number)
              payload = cv3_person.to_h
              headers = { case_number: case_number, correlation_id: hbx_id }

              event('events.fdsh.vlp.rx142.close_case_requested', attributes: payload, headers: headers)
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
