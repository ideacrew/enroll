# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Families
    module SugarCrm
      # Class for publishing the results of updated families to Sugar CRM, if enabled
      class PublishFamily
        send(:include, Dry::Monads[:result, :do])
        include Dry::Monads[:result, :do]
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

        def construct_payload_hash(family)
          payload_hash = Operations::Transformers::FamilyTo::Cv3Family.new.call(family)
          if !family.is_a?(::Family)
            Failure("Invalid Family Object. Family class is: #{family.class}")
          elsif send_to_gateway?(family, payload_hash.value!)
            payload_hash
          else
            Failure("No critical changes made to family, no update needed to CRM gateway.")
          end
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
