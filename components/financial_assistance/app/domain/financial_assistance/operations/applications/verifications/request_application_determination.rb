# frozen_string_literal: true

module FinancialAssistance
  module Operations
    module Applications
      module Verifications
        # This class is responsible for validating an application object and constructing a payload entity for FDSH service.
        class RequestApplicationDetermination
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
            payload_entity = yield validate_and_construct_application_payload(application)
            event_result = yield build_event(payload_entity, application)
            publish_result = yield publish_event_result(event_result)

            Success(publish_result)
          end

          private

          def validate_and_construct_application_payload(application)
            payload_entity = ::Operations::Fdsh::BuildAndValidateApplicationPayload.new.call(application)

            if payload_entity.success? && EnrollRegistry.feature_enabled?(:validate_and_record_publish_application_errors)
              applicant_evidence_validations, invalid_income_evidence_errors_by_id = check_all_applicant_evidences(payload_entity.value!, application)

              # only stop submission of application if all evidence types for every applicant are invalid
              handle_invalid_income_evidence(application, invalid_income_evidence_errors_by_id) unless invalid_income_evidence_errors_by_id.empty?
              return Failure('All applicantion evidences invalid') if applicant_evidence_validations.flatten.all?(&:failure?)
            end
            payload_entity
          end

          def check_all_applicant_evidences(payload_entity, application)
            invalid_income_evidence_errors_by_id = []
            applicant_evidences = payload_entity.applicants.map do |mma_applicant|
              # create an array of all evidence types held by the applicant
              applicant_evidence_keys = EVIDENCE_ALIASES.values.map { |evidence_type| mma_applicant.send(evidence_type)&.key }.compact
              faa_applicant = application.applicants.find_by { |a| a.person_hbx_id == mma_applicant.person_hbx_id }

              # need to run validations against all evidence types for all applicants -- different evidence types _may_ require different validations
              applicant_evidence_keys.map do |evidence_key|
                evidence_validation = ::Operations::Fdsh::PayloadEligibility::CheckApplicantEligibilityRules.new.call(mma_applicant, evidence_key)
                if evidence_validation.failure?
                  invalid_income_evidence_errors_by_id << "#{mma_applicant.person_hbx_id} - #{evidence_validation.failure}" if evidence_key == :income
                  handle_invalid_non_income_evidence(faa_applicant, evidence_key, evidence_validation.failure) if evidence_key != :income
                end

                evidence_validation
              end
            end

            [applicant_evidences, invalid_income_evidence_errors_by_id]
          end

          def handle_invalid_non_income_evidence(faa_applicant, evidence_type, failure_message)
            evidence_alias = EVIDENCE_ALIASES[evidence_type]
            evidence = faa_applicant.send(evidence_alias)
            failure_message = "#{evidence_type.to_s.titleize} Determination Request Failed due to #{failure_message}"

            evidence.determine_mec_evidence_aasm_status
            evidence.add_verification_history("Hub Request Failed", failure_message, "system")
          end

          def handle_invalid_income_evidence(financial_assistance_application, invalid_app_ids)
            failure_message = "Income Evidence Determination Request Failed due to invalid fields on the following applicants: #{invalid_app_ids.join(', ')}"

            financial_assistance_application.applicants.select(&:income_evidence).each do |applicant|
              applicant.income_evidence.determine_income_evidence_aasm_status
              applicant.income_evidence.add_verification_history("Hub Request Failed", failure_message, "system")
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