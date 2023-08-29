# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Fdsh
    # This class is responsible for validating an application object and constructing a payload entity for FDSH service.
    class EvidenceVerificationRequest
      include Dry::Monads[:result, :do]

      def call(evidence, event)
        application = evidence.evidenceable.application
        response = send_fdsh_hub_call(evidence)

        if response.failure? && EnrollRegistry.feature_enabled?(:validate_and_record_publish_application_errors)
          determine_evidence_aasm_status(application, evidence) if evidence.evidenceable.has_enrolled_health_coverage

          update_reason = "#{evidence.key.capitalize} Evidence Verification Request Failed due to #{response.failure}"
          evidence.add_verification_history("Hub Request Failed", update_reason, "System")
          false
        elsif response.failure?
          # Original determination method returned only false on failure -- keeping this as to not break existing functionality/specs
          false
        else
          evidence.add_verification_history(event[:action_name], event[:update_reason], event[:updated_by])
          response
        end
      end

      private

      def send_fdsh_hub_call(evidence)
        payload_entity = yield build_and_validate_payload_entity(evidence)
        event_result = yield build_event(payload_entity.to_h, evidence)
        event_result.publish ? Success() : Failure("Event failed to publish")
      end

      def build_and_validate_payload_entity(evidence)
        application = evidence.evidenceable.application
        Operations::Fdsh::BuildAndValidateApplicationPayload.new.call(application, evidence.key)
      end

      def build_event(payload, evidence)
        fdsh_events = ::Eligibilities::Evidence::FDSH_EVENTS
        headers = evidence.key == :local_mec ? { payload_type: 'application', key: 'local_mec_check' } : { correlation_id: payload[:hbx_id] }
        evidence.event(fdsh_events[evidence.key], attributes: payload, headers: headers)
      end

      def determine_evidence_aasm_status(application, evidence)
        if aptc_active?(application) || csr_code_active?(evidence)
          evidence.negative_response_received
        else
          evidence.move_to_outstanding
        end
      end

      def aptc_active?(application)
        eligibilities = application.eligibility_determinations
        eligibilities.any? { |el| el.max_aptc > 0 }
      end

      def csr_code_active?(evidence)
        applicant = evidence.evidenceable
        csr_codes = EnrollRegistry[:validate_and_record_publish_application_errors].setting(:csr_codes).item

        applicant_csr_code = ::EligibilityDetermination::CSR_KIND_TO_PLAN_VARIANT_MAP[applicant.csr_eligibility_kind]
        csr_codes.include?(applicant_csr_code)
      end
    end
  end
end