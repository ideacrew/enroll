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
        response = send_fdsh_hub_call(application, evidence)

        if response.failure? && EnrollRegistry.feature_enabled?(:validate_and_record_publish_application_errors)
          determine_evidence_aasm_status(application, evidence)

          update_reason = "#{evidence.key} Evidence Verification Request Failed due to #{result.failure}"
          evidence.add_verification_history(action: "Hub Request Failed", modifier: "System", update_reason: update_reason)

          # Original determination method returned false on failure -- keep this as to not break existing functionality/specs?
          return false
        elsif response.failure?
          # Original determination method returned false on failure -- keep this as to not break existing functionality/specs?
          return false
        else
          evidence.add_verification_history(event[:action_name], event[:update_reason], event[:updated_by])
          response
        end
      end

      private

      def send_fdsh_hub_call(application, evidence)
        payload_entity = yield build_and_validate_payload_entity(evidence)
        event_result = yield build_event(payload_entity.to_h, application)
        yield event_result.publish
      end

      def build_and_validate_payload_entity(evidence)
        application = evidence.evidenceable.application
        Operations::Fdsh::BuildAndValidateApplicationPayload.new.call(application, evidence.key)
      end

      def build_event(payload, application)
        headers = self.key == :local_mec ? { payload_type: 'application', key: 'local_mec_check' } : { correlation_id: payload[:hbx_id] }
        event(FDSH_EVENTS[self.key], attributes: payload, headers: headers)
      end

      # The below methods could arguably be placed into an application_error_handling class

      def determine_evidence_aasm_status(application, evidence)

        binding.irb
        eligibilities = application.eligibility_determinations
        family = application.family
        binding.irb

        case

        # addtl check for active/valid enrollment?
        when aptc_active?(eligibilities)
          update_evidence_aasm_state(evidence, :negative_response_received)
        when csr_eligible?(evidence)
          update_evidence_aasm_state(evidence, :negative_response_received)
          
          # change aasm to negative_response_received
        else
          update_evidence_aasm_state(evidence, :outstanding)
          # change aasm to outstanding
        end

        # create event verification history
      end

      def aptc_active?(eligibilities)
        eligibilities.any? { |el| el.max_aptc > 0 }
      end

      def csr_eligible?(evidence)
        # Navigate thru evidence
        Operations::Transformers::FamilyTo::Cv3Family.new.call(family)
      end

      def update_evidence_aasm_state(evidence, state)
        evidence.update(aasm_state: state)
      end
    end
  end
end