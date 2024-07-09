# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'aca_entities/magi_medicaid/libraries/iap_library'

module FinancialAssistance
  module Operations
    module Applications
      module MedicaidGateway
        # medicaid Gateway
        class RequestMecCheck
          # Requests MEC Check from Medicaid Gateway

          include Dry::Monads[:do, :result]
          include Acapi::Notifiers

          def call(person_id)
            person                = yield find_person(person_id)
            payload_params        = yield construct_payload(person)
            payload               = yield publish(payload_params)

            Success(payload)
          end

          private

          def find_person(person_id)
            person = ::Person.find_by(hbx_id: person_id)
            Success(person)
          rescue Mongoid::Errors::DocumentNotFound
            Failure("Unable to find Person with ID #{person_id}.")
          end

          def transform_person(person)
            ::Operations::Transformers::PersonTo::Cv3Person.new.call(person)
          end

          def construct_payload(person)
            transformed_person = transform_person(person)
            if transformed_person.success?
              person_hash = transformed_person.value!
              payload = {}
              payload[:family_id] = person.primary_family.id
              payload[:person] = person_hash
              payload[:type] = "person"

              Success(payload)
            else
              transformed_person.failure
            end
          end

          # publish xml to medicaid gateway using event source
          def publish(payload)
            FinancialAssistance::Operations::Applications::MedicaidGateway::PublishMecCheck.new.call(payload, "person")
          end
        end
      end
    end
  end
end
