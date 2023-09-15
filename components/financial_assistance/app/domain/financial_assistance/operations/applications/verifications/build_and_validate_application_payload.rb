# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Applications
      module Verifications
        # This class is responsible for validating an application object and constructing a payload entity for FDSH service.
        class BuildAndValidateApplicationPayload
          include Dry::Monads[:result, :do]

          def call(application, can_check_rules: true)
            cv3_application = yield construct_cv3_application(application)
            payload_entity = yield construct_payload_entity(cv3_application)
            yield check_eligibility_rules(payload_entity, application) if can_check_rules && EnrollRegistry.feature_enabled?(:validate_and_record_publish_application_errors)

            Success(payload_entity)
          end

          private

          def construct_cv3_application(application)
            if application.is_a?(::FinancialAssistance::Application)

              begin
                ::FinancialAssistance::Operations::Applications::Transformers::ApplicationTo::Cv3Application.new.call(application)
              rescue StandardError => e
                Failure(e.message)
              end
            else
              Failure("Could not generate CV3 Application -- wrong object type")
            end
          end

          def construct_payload_entity(cv3_application)
            # the result from the InitializeApplication call here returns a failure if malformed/errors present -- no need to add additional error handling here
            AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(cv3_application)
          end


          def check_eligibility_rules(magi_medicaid_application, financial_assistance_application)
            invalid_applicant_array = magi_medicaid_application.applicants.map do |mma_applicant|
              checked_applicant = ::FinancialAssistance::Operations::Applications::Verifications::CheckEligibilityRules.new.call(mma_applicant)
              next if checked_applicant.success?

              faa_applicant = financial_assistance_application.applicants.find_by{|a| a.person_hbx_id == mma_applicant.person_hbx_id}
              log_invalid_evidence_to_history(faa_applicant, checked_applicant.failure)

              faa_applicant
            end.compact

            return Failure('All applicants invalid') if invalid_applicant_array.length == financial_assistance_application.applicants.length

            if invalid_applicant_array.any? { |app| app.income_evidence }
              invalid_app_ids = invalid_applicant_array.select { |app| app.income_evidence }.map(&:person_hbx_id) #.to_sentence
              log_invalid_income_evidence_to_history(financial_assistance_application, invalid_app_ids)
              return Failure('All applicants invalid because any income invalid')
            end

            Success()
          end


          def log_invalid_evidence_to_history(faa_applicant, failure_message)
            evidence_types = Array.new(::FinancialAssistance::Applicant::EVIDENCES)
            evidence_types -= [:income_evidence] #income evidence error logging handled at family level, with log_invalid_income_evidence_to_history() def

            evidence_types.each do |evidence_type|
              next unless faa_applicant.send(evidence_type)

              evidence = faa_applicant.send(evidence_type)
              failure_message = "#{evidence_type.to_s.titleize} Determination Request Failed due to #{failure_message}"

              evidence.determine_mec_evidence_aasm_status
              evidence.add_verification_history("Hub Request Failed", failure_message, "system")
            end
          end


          def log_invalid_income_evidence_to_history(financial_assistance_application, invalid_app_ids)
            failure_message = "Income Evidence Determination Request Failed due to Invalid SSN on applicants #{invalid_app_ids.to_sentence}"

            financial_assistance_application.applicants.each do |applicant|
              applicant.income_evidence.determine_income_evidence_aasm_status
              applicant.income_evidence.add_verification_history("Hub Request Failed", failure_message, "system")
            end
          end


        end
      end
    end
  end
end