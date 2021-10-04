# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module People
    module SugarCrm
      # Class for publishing the results of primary subscriber to CRM Gateway
      class PublishPrimarySubscriber
        send(:include, Dry::Monads[:result, :do])
        include Dry::Monads[:result, :do]
        include EventSource::Command
        include EventSource::Logging

        def call(primary_subscriber_person)
          transformed_person = yield construct_payload_hash(primary_subscriber_person)
          #payload_value = yield validate_payload(transformed_person)
          simplified_person_payload = simplify_crm_person_payload(transformed_person)
          #payload_entity = yield create_payload_entity(simplified_person_payload)
          event = yield build_event(simplified_person_payload)
          result = yield publish(event)
          Success(result)
        end

        private

        def construct_payload_hash(person)
          if person.is_a?(::Person)
            Operations::Transformers::PersonTo::Cv3Person.new.call(person)
          else
            Failure("Invalid Person Object. Person class is: #{person.class}")
          end
        end

        def simplify_crm_person_payload(transformed_person)
          unnecessary_document_keys = %i[
            vlp_documents
            ridp_documents
            verification_type_history_elements
            local_residency_responses
            local_residency_requests
          ]
          transformed_person[:person_demographics][:no_ssn] = transformed_person[:person_demographics][:no_ssn].to_s
          unnecessary_document_keys.each do |sym_value|
            transformed_person[:consumer_role][sym_value] = [] if transformed_person[:consumer_role]
          end
          transformed_person[:individual_market_transitions] = []
          transformed_person[:verification_types] = []
          transformed_person
        end

        def build_event(payload)
          event('events.crm_gateway.people.primary_subscriber_update', attributes: payload.to_h)
        end

        def validate_payload(transformed_person)
          simplified_person_payload = simplify_crm_person_payload(transformed_person)
          result = AcaEntities::Contracts::People::PersonContract.new.call(simplified_person_payload)
          if result.success?
            result
          else
            Failure("Person with hbx_id #{result[:hbx_id]} is not valid due to #{result.errors.to_h}.")
          end
        end

        def create_payload_entity(payload_value)
          Success(AcaEntities::People::Person.new(payload_value.to_h))
        end

        def publish(event)
          event.publish
          Success("Successfully published payload to CRM Gateway.")
        end
      end
    end
  end
end
