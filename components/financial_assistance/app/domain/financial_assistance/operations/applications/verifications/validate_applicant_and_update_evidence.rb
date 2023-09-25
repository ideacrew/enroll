# frozen_string_literal: true

module FinancialAssistance
  module Operations
    module Applications
      module Verifications
        # This class handles the validation of an applicant and updates the evidences as needed
        class ValidateApplicantAndUpdateEvidence
          include Dry::Monads[:result, :do]

          EVIDENCE_ALIASES = {
            income: :income_evidence,
            esi_mec: :esi_evidence,
            non_esi_mec: :non_esi_evidence,
            local_mec: :local_mec_evidence
          }.freeze

          def call(payload_entity, application)
            yield check_all_applicant_evidences(payload_entity, application)
            Success(payload_entity)
          end

          private

          def check_all_applicant_evidences(payload_entity, application)
            income_evidence_errors = []
            evidence_validations = payload_entity.applicants.map do |mma_applicant|
              evidence_keys, faa_applicant = get_applicant_info(application, mma_applicant)

              # need to run validations against all evidence types for all applicants -- different evidence types _may_ require different validations
              evidence_keys.map do |evidence_key|
                evidence_validation = ::Operations::Fdsh::PayloadEligibility::CheckApplicantEligibilityRules.new.call(mma_applicant, evidence_key)
                if evidence_validation.failure?
                  income_evidence_errors << "#{mma_applicant.person_hbx_id} - #{evidence_validation.failure}" if evidence_key == :income
                  handle_invalid_non_income_evidence(faa_applicant, evidence_key, evidence_validation.failure) if evidence_key != :income
                end

                evidence_validation
              end
            end
            handle_invalid_income_evidence(application, income_evidence_errors) unless income_evidence_errors.empty?
            return Failure('All applicantion evidences invalid') if evidence_validations.flatten.all?(&:failure?)

            Success(evidence_validations)
          end

          def get_applicant_info(application, mma_applicant)
            # create an array of all evidence types held by the applicant
            evidence_keys = EVIDENCE_ALIASES.each_value.map { |evidence_type| mma_applicant.send(evidence_type)&.key }.compact
            faa_applicant = application.applicants.find_by { |a| a.person_hbx_id == mma_applicant.person_hbx_id }

            [evidence_keys, faa_applicant]
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
        end
      end
    end
  end
end