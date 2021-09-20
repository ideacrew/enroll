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

          include Dry::Monads[:result, :do]
          include Acapi::Notifiers

          # add comment here
          def call(application_id:, person_id:)
            application           = yield find_application(application_id)
            person                = yield find_person(person_id)
            payload_params        = yield construct_payload(person, application)
            payload               = yield publish(payload_params)

            Success(payload) #switch variable as methods done
          end

          private

          def find_application(application_id)
            application = FinancialAssistance::Application.find(application_id)

            Success(application)
          rescue Mongoid::Errors::DocumentNotFound
            Failure("Unable to find Application with ID #{application_id}.")
          end

          def find_person(person_id)
            person = ::Person.find_by(hbx_id: person_id)

            Success(person)
          rescue Mongoid::Errors::DocumentNotFound
            Failure("Unable to find Person with ID #{person_id}.")
          end

          def construct_payload(person, application)
            person_hash = Operations::Transformers::PersonTo::Cv3Person.new.call(person).value!
            payload = {}
            payload[:application] = application.hbx_id
            payload[:fam] = ::Family.find(application.family_id).hbx_assigned_id.to_s
            payload[:person] = person_hash
            puts payload
            Success(payload)
          end

          # publish xml to medicaid gateway using event source
          def publish(payload)
            FinancialAssistance::Operations::Applications::MedicaidGateway::PublishMecCheck.new.call(payload)
          end
        end
      end
    end
  end
end
