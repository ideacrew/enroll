# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'aca_entities/magi_medicaid/libraries/iap_library'

module FinancialAssistance
  module Operations
    module Applications
      module Pvc
        module Medicare
          # This Operation determines applicants pvc medicare eligibility
          # Operation receives the Application with renewal medicare determination values
          class AddPvcMedicareDetermination
            include Dry::Monads[:result, :do]

            # @param [Hash] opts The options to add pvc medicare determination to applicants
            # @option opts [Hash] :application_response_payload ::AcaEntities::MagiMedicaid::Application params
            # @return [Dry::Monads::Result]
            def call(params)
              application_entity = yield initialize_application_entity(params[:payload])
              application = yield find_application(application_entity)
              result = yield update_applicant(application_entity, application, params[:applicant_identifier])

              Success(result)
            end

            private

            def initialize_application_entity(params)
              application_entity = ::AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(params)
              return log_and_return_failure("Failed to initialize application with hbx_id: #{params[:hbx_id]}") if application_entity.failure?

              application_entity
            end

            def find_application(application_entity)
              application = ::FinancialAssistance::Application.by_hbx_id(application_entity.hbx_id).first
              application.present? ? Success(application) : log_and_return_failure("Could not find application with given hbx_id: #{application_entity.hbx_id}")
            end

            def update_applicant(response_app_entity, application, applicant_identifier)
              enrollments = HbxEnrollment.where(:aasm_state.in => HbxEnrollment::ENROLLED_STATUSES, family_id: application.family_id)
              response_applicant = response_app_entity.applicants.detect {|applicant| applicant.person_hbx_id == applicant_identifier}
              applicant = application.applicants.where(person_hbx_id: applicant_identifier).first

              return log_and_return_failure("applicant not found with #{applicant_identifier} for pvc Medicare") unless applicant
              return log_and_return_failure("applicant not found in response with #{applicant_identifier} for pvc Medicare") unless response_applicant

              update_applicant_verifications(applicant, response_applicant, enrollments)
              Success('Successfully updated Applicant with evidences and verifications')
            rescue StandardError => e
              log_and_return_failure("Failed to update_applicant with hbx_id #{applicant&.person_hbx_id} due to #{e.inspect}")
            end

            def update_applicant_verifications(applicant, response_applicant_entity, enrollments)
              response_non_esi_evidence = response_applicant_entity.non_esi_evidence
              applicant_non_esi_evidence = applicant.non_esi_evidence

              if applicant_non_esi_evidence.present?
                if response_non_esi_evidence.aasm_state == 'outstanding'
                  if enrolled?(applicant, enrollments)
                    due_date = fetch_evidence_due_date_for_bulk_actions(applicant_non_esi_evidence, response_non_esi_evidence)
                    applicant.set_evidence_outstanding(applicant_non_esi_evidence, due_date)
                  else
                    applicant.set_evidence_to_negative_response(applicant_non_esi_evidence)
                  end
                else
                  applicant.set_evidence_attested(applicant_non_esi_evidence)
                end

                if response_non_esi_evidence.request_results.present?
                  response_non_esi_evidence.request_results.each do |eligibility_result|
                    applicant_non_esi_evidence.request_results << Eligibilities::RequestResult.new(eligibility_result.to_h)
                  end
                end
                applicant.save!
              end

              Success(applicant)
            end

            def fetch_evidence_due_date_for_bulk_actions(applicant_non_esi_evidence, response_evidence)
              return if response_evidence.request_results.blank?
              return applicant_non_esi_evidence.due_on if applicant_non_esi_evidence.due_on.present?
              return unless response_evidence.request_results.any? do |result|
                FinancialAssistance::Applicant::BULK_REDETERMINATION_ACTION_TYPES.include?(result.action)
              end

              TimeKeeper.date_of_record + EnrollRegistry[:bulk_call_verification_due_in_days].item.to_i
            end

            def enrolled?(applicant, enrollments)
              return false if enrollments.blank?

              family_member_ids = enrollments.flat_map(&:hbx_enrollment_members).flat_map(&:applicant_id).uniq
              family_member_ids.map(&:to_s).include?(applicant.family_member_id.to_s)
            end

            def log_and_return_failure(message)
              pvc_logger.error(message)
              Failure(message)
            end

            def pvc_logger
              @pvc_logger ||= Logger.new("#{Rails.root}/log/pvc_non_esi_logger_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
            end
          end
        end
      end
    end
  end
end
