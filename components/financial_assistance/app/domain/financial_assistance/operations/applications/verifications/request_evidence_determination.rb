# frozen_string_literal: true

module FinancialAssistance
  module Operations
    module Applications
      module Verifications
        # This class is responsible for validating an application object and constructing a payload entity for FDSH service.
        class RequestEvidenceDetermination
          include Dry::Monads[:do, :result]
          include Acapi::Notifiers
          include EventSource::Command

          EVIDENCE_ALIASES = {
            income: :income_evidence,
            esi_mec: :esi_evidence,
            non_esi_mec: :non_esi_evidence,
            local_mec: :local_mec_evidence
          }.freeze

          def call(application)
            yield update_application_evidence_histories(application)
            payload_entity = yield validate_and_construct_application_payload(application)
            event_result = yield build_event(payload_entity, application)
            publish_result = yield publish_event_result(event_result)

            Success(publish_result)
          end

          private

          # UpdateEvidenceHistories of Application
          def update_application_evidence_histories(application)
            application.update_evidence_histories
            Success()
          end

          def validate_and_construct_application_payload(application)
            payload_entity = ::Operations::Fdsh::BuildAndValidateApplicationPayload.new.call(application)
            return payload_entity unless EnrollRegistry.feature_enabled?(:validate_and_record_publish_application_errors)
            return handle_malformed_payload_entity(payload_entity, application) if payload_entity.failure?

            FinancialAssistance::Operations::Applications::Verifications::ValidateApplicantAndUpdateEvidence.new.call(payload_entity.value!, application)
          end

          def handle_malformed_payload_entity(payload_entity, application)
            error_message = payload_entity.failure
            update_all_evidences(application, error_message)

            Failure(error_message)
          end

          def update_all_evidences(application, error_message)
            application.applicants.each do |applicant|
              EVIDENCE_ALIASES.each_values.each do |evidence_key|
                evidence = applicant.send(evidence_key)
                next unless evidence

                method = "determine_#{evidence.key.split('_').last}_evidence_aasm_status"
                evidence.send(method)

                evidence.add_verification_history("Hub Request Failed", error_message, "system")
              end
            end
          end

          def build_event(payload, application)
            local_mec_check = application.is_local_mec_checkable?
            headers = { correlation_id: application.hbx_id }
            headers.merge!(payload_type: 'application', key: 'local_mec_check') if local_mec_check
            event('events.iap.applications.magi_medicaid_application_determined', attributes: payload.to_h, headers: headers.merge!(payload_format))
          end

          def payload_format
            {
              non_esi_payload_format: EnrollRegistry[:non_esi_h31].setting(:payload_format).item,
              esi_mec_payload_format: EnrollRegistry[:esi_mec].setting(:payload_format).item,
              ifsv_payload_format: EnrollRegistry[:ifsv].setting(:payload_format).item
            }
          end

          def publish_event_result(event_result)
            event_result.publish ? Success("Event published successfully") : Failure("Event failed to publish")
          end
        end
      end
    end
  end
end