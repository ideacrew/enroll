# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Policies
    # Publish event after find and transform family to cv3 family.
    class BuildCv3FamilyFromPolicy
      include Dry::Monads[:result, :do, :try]
      include EventSource::Command

      def call(params)
        enrollment = yield find_hbx_enrollment(params[:policy_id])
        family     = yield find_family(enrollment)
        cv3_family = yield transform_family(family)
        payload    = yield validate_payload(cv3_family)
        _result    = yield build_and_publish_event(payload, enrollment.effective_on.year)

        Success("Successfully published Family with id #{family.id}")
      end

      private

      def find_hbx_enrollment(policy_id)
        Operations::HbxEnrollments::Find.new.call({hbx_id: policy_id })
      end

      def find_family(enrollment)
        Success(enrollment.family)
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

      def build_and_publish_event(payload, year)
        event = event("events.irs_groups.built_requested_seed", attributes: { payload: payload.to_h,
                                                                              year: year }).value!
        Success(event.publish)
      end
    end
  end
end
