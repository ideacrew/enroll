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
          binding.irb
          determine_evidence_aasm_status(application, evidence) if evidence.evidenceable.has_enrolled_health_coverage
          binding.irb

          update_reason = "#{evidence.key} Evidence Verification Request Failed due to #{response.failure}"
          evidence.add_verification_history(action: "Hub Request Failed", modifier: "System", update_reason: update_reason)

          # Original determination method returned false on failure -- keeping this as to not break existing functionality/specs
          false
        elsif response.failure?
          # Original determination method returned false on failure -- keeping this as to not break existing functionality/specs
          false
        else
          evidence.add_verification_history(event[:action_name], event[:update_reason], event[:updated_by])
          response
        end
      end

      private

      def send_fdsh_hub_call(evidence)
        payload_entity = yield build_and_validate_payload_entity(evidence)
        event_result = yield build_event(payload_entity.to_h, evidence.key)
        yield event_result.publish
      end

      def build_and_validate_payload_entity(evidence)
        application = evidence.evidenceable.application
        Operations::Fdsh::BuildAndValidateApplicationPayload.new.call(application, evidence.key)
      end

      def build_event(payload, evidence_key)
        fdsh_events = ::Eligibilities::Evidence::FDSH_EVENTS
        headers = evidence_key == :local_mec ? { payload_type: 'application', key: 'local_mec_check' } : { correlation_id: payload[:hbx_id] }
        event(fdsh_events[self.key], attributes: payload, headers: headers)
      end

      def determine_evidence_aasm_status(application, evidence)
        binding.irb
        case

        when aptc_active?(application)
          update_evidence_aasm_state(evidence, :negative_response_received)

        when csr_eligible?(evidence)
          update_evidence_aasm_state(evidence, :negative_response_received)

        else
          update_evidence_aasm_state(evidence, :outstanding)
        end
      end

      def aptc_active?(application)
        eligibilities = application.eligibility_determinations
        eligibilities.any? { |el| el.max_aptc > 0 }
      end

      def csr_eligible?(evidence)
        binding.irb
        applicant = evidence.evidenceable
        binding.irb
        csr_codes = EnrollRegistry[:validate_and_record_publish_application_errors].setting(:csr_codes).item
        binding.irb
        applicant_csr_code = ::EligibilityDetermination::CSR_KIND_TO_PLAN_VARIANT_MAP[applicant.csr_eligibility_kind]
        binding.irb
        csr_codes.include?(applicant_csr_code)
      end

      def update_evidence_aasm_state(evidence, state)
        evidence.update(aasm_state: state)
      end
    end
  end
end