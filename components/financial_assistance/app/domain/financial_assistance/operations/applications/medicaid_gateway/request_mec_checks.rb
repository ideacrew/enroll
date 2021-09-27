# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'aca_entities/magi_medicaid/libraries/iap_library'

module FinancialAssistance
  module Operations
    module Applications
      module MedicaidGateway
        # medicaid Gateway
        class RequestMecChecks
          # Requests multiple MEC Checks from Medicaid Gateway

          include Dry::Monads[:result, :do]
          include Acapi::Notifiers

          def call(application_id)            
            application           = yield find_application(application_id)
            family                = yield find_family(application)
            people                = yield get_people(application)
            transformed_people    = yield transform_people(people)
            payload_params        = yield construct_payload(application, family, transformed_people)
            payload               = yield publish(payload_params)

            Success(payload)
          end

          private

          def find_application(application_id)
            application = ::FinancialAssistance::Application.find(application_id)

            Success(application)
          rescue Mongoid::Errors::DocumentNotFound
            Failure("Unable to find Application with ID #{application_id}.")
          end

          def find_family(application)
            family = ::Family.find(application.family_id)

            Success(family)
          rescue Mongoid::Errors::DocumentNotFound
            Failure("Unable to find Family with ID #{application.family_id}.")
          end

          def get_people(application)
            result = []
            application.applicants.map(&:person_hbx_id).each do |person_id|
              result << find_person(person_id)
            end
            Success(result)
          end

          def find_person(person_id)
            person = ::Person.find_by(hbx_id: person_id)
          end

          def transform_people(people)
            transformed_people = []
            people.collect do |person|
              result = Operations::Transformers::PersonTo::Cv3Person.new.call(person)
              return result unless result.success?
              transformed_people << result.value!
            end
            Success(transformed_people)
          end

          def construct_payload(application, family, people)
            payload = {}
            payload[:application] = application.id
            payload[:family_id] = family.hbx_assigned_id.to_s
            payload[:people] = people
            payload[:type] = "application"

            Success(payload)
          end

          # publish xml to medicaid gateway using event source
          def publish(payload)
            # binding.pry
            FinancialAssistance::Operations::Applications::MedicaidGateway::PublishMecCheck.new.call(payload)
          end
        end
      end
    end
  end
end
