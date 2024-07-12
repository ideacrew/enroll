# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module People
    module SugarCrm
      # Class for publishing the results of primary subscriber to CRM Gateway
      class PublishPrimarySubscriber
        include Dry::Monads[:do, :result]
        include Dry::Monads[:do, :result]
        include EventSource::Command
        include EventSource::Logging

        def call(primary_subscriber_person)
          transformed_person = yield construct_payload_hash(primary_subscriber_person)
          simplified_person_payload = simplify_crm_person_payload(transformed_person)
          event = yield build_event(simplified_person_payload, primary_subscriber_person)
          result = yield publish(event)
          Success([result, transformed_person])
        end

        private

        # Updates should only be made to CRM gateway if critical attributes are changed
        # or new family members are added/deleted
        def send_to_gateway?(person, new_payload)
          if EnrollRegistry.feature_enabled?(:check_for_crm_updates)
            person.crm_notifiction_needed
          else
            old_payload = person.cv3_payload
            return true if old_payload.blank?
            new_payload_hash = new_payload.to_h.with_indifferent_access
            old_payload_hash = old_payload.to_h.with_indifferent_access
            new_payload_changes = {
              encrypted_ssn: new_payload_hash.dig(:person_demographics, :encrypted_ssn),
              first_name: new_payload_hash.dig(:person_demographics, :first_name),
              last_name: new_payload_hash.dig(:person_demographics, :last_name),
              dob: new_payload_hash.dig(:person_demographics, :dob),
              addresses: new_payload_hash[:addresses],
              phones: new_payload_hash[:phones]
            }
            old_payload_changes = {
              encrypted_ssn: old_payload_hash.dig(:person_demographics, :encrypted_ssn),
              first_name: old_payload_hash.dig(:person_demographics, :first_name),
              last_name: old_payload_hash.dig(:person_demographics, :last_name),
              dob: old_payload_hash.dig(:person_demographics, :dob),
              addresses: old_payload_hash[:addresses],
              phones: old_payload_hash[:phones]
            }
            new_payload_changes != old_payload_changes
          end
        end


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
            transformed_person[:consumer_role] && transformed_person[:consumer_role][sym_value] = []
          end
          transformed_person[:individual_market_transitions] = []
          transformed_person[:verification_types] = []
          transformed_person
        end

        def build_event(payload, primary_subscriber_person)
          if send_to_gateway?(primary_subscriber_person, payload)
            event('events.crm_gateway.people.primary_subscriber_update', attributes: payload.to_h)
          else
            Failure("No critical changes made to primary subscriber: #{primary_subscriber_person.hbx_id}, no update needed to CRM gateway.")
          end
        end

        def publish(event)
          event.publish
          Success("Successfully published payload to CRM Gateway.")
        end
      end
    end
  end
end
