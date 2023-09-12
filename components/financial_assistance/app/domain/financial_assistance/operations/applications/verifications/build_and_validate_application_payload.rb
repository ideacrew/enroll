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

          def check_eligibility_rules(payload, application)
            evidence_types = ::FinancialAssistance::Applicant::EVIDENCES
            applicants_by_hbx_id = {}
            application.applicants.each { |applicant| applicants_by_hbx_id[applicant.person_hbx_id] = applicant }

            # Less readable
            # applicants_by_hbx_id = Hash[application.applicants.map { |applicant| [applicant.person_hbx_id, applicant] }]

            invalid_applicant_array = payload.applicants.map do |cv3_applicant|
              valid_cv3_applicant = ::FinancialAssistance::Operations::Applications::Verifications::CheckEligibilityRules.new.call(cv3_applicant)
              applicant = retrieve_application_applicant(cv3_applicant, applicants_by_hbx_id)
              
              if valid_cv3_applicant.failure?
                evidence_types.each do |evidence_type|
                  next unless cv3_applicant.send(evidence_type)

                  handle_failed_applicant(applicant, evidence_type, valid_cv3_applicant.failure)
                  applicants_by_hbx_id[]
                end

                { applicant: applicant, failure_reason: valid_cv3_applicant.failure }
              end
            end.compact

            return Failure('No valid applicants') if invalid_applicant_array.length == application.applicants.length

            handle_application_income_evidences(invalid_applicant_array) if invalid_applicant_array.any? { |applicant| applicant.income_evidence }
            Success()
          end

          def retrieve_application_applicant(cv3_applicant, applicants_by_hbx_id)
            hbx_id = cv3_applicant.person_hbx_id
            application_applicant = applicants_by_hbx_id[hbx_id]
          end

          # The purpose of this method is to update all other evidence types that are NOT income_evidence
          # This is because income evidence is determined by family, not the individual applicant
          def handle_failed_applicant(applicant, evidence_type, failure_reason)
            evidence = applicant.send(evidence_type)
            failure_message = "#{evidence_type.to_s.titleize} Determination Request Failed due to #{failure_reason}"
            
            if evidence_type != :income_evidence
              evidence.determine_mec_evidence_aasm_status
              evidence.add_verification_history("Hub Request Failed", failure_message, "system")
            end

            Failure(failure_reason)
          end

          def handle_application_income_evidences(invalid_applicant_array)
            invalid_applicant_array[0][:failure_reason]

            # personal_hbx_id needs to be included in verification history message
            application.applicants.each do |applicant|
              if applicant.income_evidence
                applicant.income_evidence.determine_income_evidence_aasm_status
              end
            end
          end
        end
      end
    end
  end
end