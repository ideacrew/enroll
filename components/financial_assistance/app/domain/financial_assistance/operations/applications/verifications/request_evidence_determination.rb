# frozen_string_literal: true

module FinancialAssistance
  module Operations
    module Applications
      module Verifications
        # This class is responsible for validating an application object and constructing a payload entity for FDSH service.
        class RequestEvidenceDetermination
          include Dry::Monads[:result, :do]
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

          def update_application_evidence_histories(application)
            application.update_evidence_histories
            Success()
          end

          def validate_and_construct_application_payload(application)
            payload_entity = ::Operations::Fdsh::BuildAndValidateApplicationPayload.new.call(application)
            return payload_entity unless EnrollRegistry.feature_enabled?(:validate_and_record_publish_application_errors)

            FinancialAssistance::Operations::Applications::Verifications::ValidateApplicantAndUpdateEvidence.new.call(payload_entity, application)
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
              esi_mec_payload_format: EnrollRegistry[:esi_mec].setting(:payload_format).item
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