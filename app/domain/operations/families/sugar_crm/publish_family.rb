# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Families
    # Class for publishing the results of updated families to Sugar CRM, if enabled
    class PublishFamily
      send(:include, Dry::Monads[:result, :do])
      include Dry::Monads[:result, :do]
      include EventSource::Command
      include EventSource::Logging

      # @param [ Family] instance fo family
      # @return Success result
      def call(family)
        transformed_family = yield construct_payload_hash(family)
        payload_value = yield validate_payload(transformed_family)
        payload_entity = yield create_payload_entity(payload_value)
        event = yield build_event(payload_entity)
        result = yield publish(event)
        Success(result)
      end

      private

      def construct_payload_hash(family)
        if family.is_a?(::Family)
          Operations::Transformers::FamilyTo::Cv3Family.new.call(family)
        else
          Failure("Invalid Family Object. Family class is: #{family.class}")
        end
      end

      def validate_payload(transformed_family)
        # Operations::Families::PublishFamily publish payload to CRM should return success with correct family information
        # Failure/Error: result = AcaEntities::Contracts::Families::FamilyContract.new.call(transformed_family)
        #  NoMethodError:
        # undefined method `key?' for #<Money fractional:0 currency:USD>
        binding.irb
        result = AcaEntities::Contracts::Families::FamilyContract.new.call(transformed_family)
        if result.success?
          result
        else
          hbx_id = transformed_family[:family_members].detect { |fm| fm[:is_primary_applicant] }[:hbx_id]
          Failure("Person with hbx_id #{hbx_id} is not valid due to #{result.errors.to_h}.")
        end
      end

      def create_payload_entity(payload_value)
        Success(AcaEntities::Families::Family.new(payload_value.to_h))
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
