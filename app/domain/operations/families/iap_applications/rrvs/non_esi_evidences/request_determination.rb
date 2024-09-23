# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Families
    module IapApplications
      module Rrvs
        module NonEsiEvidences
          # This operation is to publish cv3 application for rrv non_esi verification
          class RequestDetermination
            include Dry::Monads[:do, :result]
            include EventSource::Command
            include EventSource::Logging

            def call(params)
              values = yield validate(params)
              application = yield fetch_application(values)
              _evidences = yield create_non_esi_evidences(application)
              cv3_application = yield transform_and_validate_application(application)
              event = yield build_event(cv3_application)
              publish(event)

              Success("Successfully published payload for rrv non esi and created history event")
            end

            private

            def validate(params)
              errors = params[:application_hbx_id].present? ? [] : ['application hbx_id is missing']
              errors.empty? ? Success(params) : Failure(errors)
            end

            def fetch_application(params)
              application = ::FinancialAssistance::Application.by_hbx_id(params[:application_hbx_id]).first
              if application.present?
                Success(application)
              else
                rrv_logger.info("No applicationfound with hbx_id #{params[:application_hbx_id]}")
                Failure("No applicationfound with hbx_id #{params[:application_hbx_id]}")
              end
            end

            def create_non_esi_evidences(application)
              application.active_applicants.each do |applicant|
                next if applicant.non_esi_evidence.present?

                applicant.create_evidence(:non_esi_mec, "Non ESI MEC")
              end

              create_evidence_history(application, 'RRV_Submitted', 'RRV - Renewal verifications submitted', 'system')
              Success(true)
            end

            def transform_and_validate_application(application)
              payload_entity = Operations::Fdsh::BuildAndValidateApplicationPayload.new.call(application)
              return payload_entity unless EnrollRegistry.feature_enabled?(:validate_and_record_publish_application_errors)

              if payload_entity.success?
                all_applicants_valid = validate_applicants(payload_entity, application)
                return all_applicants_valid.any?(&:last) ? payload_entity : Failure("Failed to transform application with hbx_id #{application.hbx_id} due to all applicants are invalid")
              elsif payload_entity.failure?
                record_application_failure(application, payload_entity.failure.messages)
              end

              payload_entity
            rescue StandardError => e
              rrv_logger.error("RRV process failed to publish event for the application with hbx_id #{application.hbx_id} due to #{e.inspect}")
              Failure("RRV process failed to publish event for the application with hbx_id #{application.hbx_id} due to #{e.inspect}")
            end

            def validate_applicants(payload_entity, application)
              eligible_applicants = application.active_applicants.select(&:non_esi_evidence)
              applicants_entity = payload_entity.value!.applicants

              eligible_applicants.map do |eligible_applicant|
                applicant_entity = applicants_entity.detect { |appl_entity| eligible_applicant.person_hbx_id == appl_entity.person_hbx_id }
                result = Operations::Fdsh::PayloadEligibility::CheckApplicantEligibilityRules.new.call(applicant_entity, :non_esi_mec)

                if result.success?
                  [applicant_entity.person_hbx_id, true]
                else
                  record_applicant_failure(eligible_applicant.non_esi_evidence, result)
                  [applicant_entity.person_hbx_id, false]
                end
              end
            end

            def record_applicant_failure(evidence, result)
              add_verification_history(evidence, 'RRV_Submission_Failed', "RRV - Renewal verifications submission failed due to #{result.failure}", 'system')
              update_evidence_to_default_state(evidence)
            end

            def record_application_failure(application, error_messages)
              create_evidence_history(application, 'RRV_Submission_Failed', "RRV - Renewal verifications submission failed due to #{error_messages}", 'system')
              update_evidence_state_for_all_applicants(application)
            end

            def build_event(cv3_application)
              event('events.families.iap_applications.rrvs.non_esi_evidences.determination_requested', attributes: { application: cv3_application.to_h })
            end

            def publish(event)
              event.publish

              Success("Successfully published payload for rrv non esi")
            end

            def create_evidence_history(application, action, update_reason, update_by)
              application.active_applicants.each do |applicant|
                evidence = applicant.non_esi_evidence
                next unless evidence.present?
                add_verification_history(evidence, action, update_reason, update_by)
              end
            end

            def add_verification_history(evidence, action, update_reason, update_by)
              evidence.add_verification_history(action, update_reason, update_by) if evidence.present?
            end

            def update_evidence_state_for_all_applicants(application)
              application.active_applicants.each do |applicant|
                update_evidence_to_default_state(applicant.non_esi_evidence)
              end
            end

            # update income evidence state to default aasm state for applicant
            def update_evidence_to_default_state(evidence)
              evidence&.determine_mec_evidence_aasm_status
            end

            def rrv_logger
              @rrv_logger ||= Logger.new("#{Rails.root}/log/rrv_non_esi_logger_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
            end
          end
        end
      end
    end
  end
end
