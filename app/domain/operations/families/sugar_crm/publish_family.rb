# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Families
    module SugarCrm
      # Class for publishing the results of updated families to Sugar CRM, if enabled
      class PublishFamily
        include Dry::Monads[:do, :result]
        include Dry::Monads[:do, :result]
        include EventSource::Command
        include EventSource::Logging

        # @param [ Family] instance of family
        # @return Success result
        def call(family)
          transformed_family = yield construct_payload_hash(family)
          event = yield build_event(transformed_family)
          result = yield publish(event)
          Success([result, transformed_family])
        end

        private

        # Updates should only be made to CRM gateway if critical attributes are changed
        # or new family members are added/deleted
        def send_to_gateway?(family, new_payload)
          if EnrollRegistry.feature_enabled?(:check_for_crm_updates)
            family.family_members.detect{|fm| fm.person.crm_notifiction_needed } || family.crm_notifiction_needed
          else
            old_payload = family.cv3_payload
            return true if old_payload.blank?
            new_payload_changes = {}
            old_payload_changes = {}
            new_payload.to_h.with_indifferent_access[:family_members].each_with_index do |fm_hash, index_num|
              fm_hash = fm_hash.with_indifferent_access
              new_payload_changes[index_num] = [
                {
                  encrypted_ssn: fm_hash.dig(:person, :person_demographics, :encrypted_ssn),
                  first_name: fm_hash.dig(:person, :person_demographics, :first_name),
                  last_name: fm_hash.dig(:person, :person_demographics, :last_name),
                  addresses: fm_hash.dig(:person, :addresses),
                  phones: fm_hash.dig(:person, :phones)
                }
              ]
            end
            old_payload.to_h.with_indifferent_access[:family_members].each_with_index do |fm_hash, index_num|
              fm_hash = fm_hash.with_indifferent_access
              old_payload_changes[index_num] = [
                {
                  encrypted_ssn: fm_hash.dig(:person, :person_demographics, :encrypted_ssn),
                  first_name: fm_hash.dig(:person, :person_demographics, :first_name),
                  last_name: fm_hash.dig(:person, :person_demographics, :last_name),
                  addresses: fm_hash.dig(:person, :addresses),
                  phones: fm_hash.dig(:person, :phones)
                }
              ]
            end
            new_payload_changes != old_payload_changes
          end
        end

        def construct_payload_hash(family)
          payload_hash = Operations::Transformers::FamilyTo::Cv3Family.new.call(family, true)
          if !family.is_a?(::Family)
            Failure("Invalid Family Object. Family class is: #{family.class}")
          elsif send_to_gateway?(family, payload_hash.value!)
            payload_hash
          else
            Failure("No critical changes made to family: #{family.id}, no update needed to CRM gateway.")
          end
        rescue StandardError => e
          # Likely failure constructing applications payload
          Rails.logger.warn("Publish Family Exception: #{e}")
          Failure(e)
        end

        def build_event(payload)
          event('events.crm_gateway.families.family_update', attributes: payload.to_h)
        end

        def publish(event)
          event.publish
          Success("Successfully published payload to CRM Gateway.")
        end
      end
    end
  end
end
