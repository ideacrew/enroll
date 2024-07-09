# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module IrsGroups
    # Publish event after find and transform family to cv3 family.
    class BuildSeedRequest
      include Dry::Monads[:do, :result]
      include EventSource::Command

      def call(family_id)
        family      = yield find_family(family_id)
        cv3_family  = yield transform_family(family)
        payload     = yield validate_payload(cv3_family)
        _result      = yield build_and_publish_event(payload)

        Success("Sucessfully published Family with id #{family_id}")
      end

      private

      def find_family(family_id)
        family = Family.find(family_id)
        Success(family)
      rescue Mongoid::Errors::DocumentNotFound
        Failure("Unable to find Family with ID #{family_id}.")
      end

      def transform_family(family)
        cv3_family = Operations::Transformers::FamilyTo::Cv3Family.new.call(family)
        cv3_family.success? ? cv3_family : Failure("unable to publish family with hbx_id #{family.hbx_assigned_id} due to #{cv3_family.failure}")
      end

      def validate_payload(value)
        result = AcaEntities::Contracts::Families::FamilyContract.new.call(value)
        if result.success?
          Success(result)
        else
          Failure("unable to publish family with hbx_id #{family.hbx_assigned_id} due to #{result.errors.to_h}")
        end
      end

      def build_and_publish_event(payload)
        event = event("events.irs_groups.built_requested_seed", attributes: payload.to_h).value!
        Success(event.publish)
      end
    end
  end
end
