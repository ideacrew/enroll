# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Fdsh
    # This class is responsible for validating an application object and constructing a payload entity for FDSH service.
    class RequestEvidenceDetermination
      include Dry::Monads[:do, :result]
      include EventSource::Command

      def call(evidence)
        payload_entity = yield build_and_validate_payload_entity(evidence)
        event_result = yield build_event(payload_entity.to_h, evidence)
        publish_result = yield publish_event_result(event_result)

        Success(publish_result)
      end

      private

      def build_and_validate_payload_entity(evidence)
        application = evidence.evidenceable.application
        payload_entity = Operations::Fdsh::BuildAndValidateApplicationPayload.new.call(application)

        if payload_entity.success? && EnrollRegistry.feature_enabled?(:validate_and_record_publish_application_errors)
          result = if evidence.key == :income
                     payload_entity.value!.applicants.collect do |applicant_entity|
                       check_eligibility_rules(applicant_entity, evidence.key)
                     end
                   else
                     applicant_entity = payload_entity.value!.applicants.select { |applicant| applicant.person_hbx_id == evidence.evidenceable.person_hbx_id }.first
                     [check_eligibility_rules(applicant_entity, evidence.key)]
                   end

          if result.any?(Failure)
            errors = result.select { |r| r.is_a?(Failure) }.map(&:failure).flatten.compact
            return Failure(errors)
          end
        end
        payload_entity
      end

      def check_eligibility_rules(applicant_entity, request_type)
        Operations::Fdsh::PayloadEligibility::CheckApplicantEligibilityRules.new.call(applicant_entity, request_type)
      end

      def build_event(payload, evidence)
        fdsh_events = ::Eligibilities::Evidence::FDSH_EVENTS
        headers = evidence.key == :local_mec ? { payload_type: 'application', key: 'local_mec_check' } : { correlation_id: payload[:hbx_id] }
        formatted_payload = evidence.payload_format

        event(fdsh_events[evidence.key], attributes: payload, headers: headers.merge!(formatted_payload))
      end

      def publish_event_result(event_result)
        event_result.publish ? Success("Event published successfully") : Failure("Event failed to publish")
      end
    end
  end
end