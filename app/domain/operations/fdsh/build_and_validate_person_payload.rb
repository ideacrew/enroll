# frozen_string_literal: true

# generate

module Operations
  module Fdsh
    # This class is responsible for validating a person object and constructing a payload entity for FDSH service.
    class BuildAndValidatePersonPayload
      include Dry::Monads[:do, :result]

      def call(person, request_type, can_check_rules: true)
        payload_param = yield construct_payload_hash(person)
        payload_value = yield validate(payload_param)
        payload_entity = yield create_payload_entity(payload_value)
        yield check_eligibility_rules(payload_entity, request_type) if can_check_rules && EnrollRegistry.feature_enabled?(:validate_and_record_publish_errors)

        Success(payload_entity)
      end

      private

      def construct_payload_hash(person)
        if person.is_a?(::Person)
          Operations::Transformers::PersonTo::Cv3Person.new.call(person)
        else
          Failure("Invalid Person Object")
        end
      end

      def validate(value)
        result = AcaEntities::Contracts::People::PersonContract.new.call(value)
        if result.success?
          Success(result)
        else
          hbx_id = value[:hbx_id]
          Failure("Person with hbx_id #{hbx_id} is not valid due to #{result.errors.to_h}.")
        end
      end

      def create_payload_entity(value)
        Success(AcaEntities::People::Person.new(value.to_h))
      end

      def check_eligibility_rules(payload, request_type)
        Operations::Fdsh::PayloadEligibility::CheckPersonEligibilityRules.new.call(payload, request_type)
      end
    end
  end
end