# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'aca_entities/magi_medicaid/libraries/iap_library'

module FinancialAssistance
  module Operations
    module Applications
      module Pvc
        # operation to manually trigger pvc events.
        # It will take families as input and find the determined application, add evidences and publish the group of applications
        class CreatePvcRequest
          include Dry::Monads[:do, :result]
          include EventSource::Command
          include EventSource::Logging
          include FinancialAssistance::JobsHelper

          def call(params)
            values = yield validate(params)
            application = yield fetch_application(values)
            _evidences = yield create_non_esi_evidences(application)
            cv3_application = yield transform_and_validate_application(application)
            event = yield build_event(cv3_application)
            publish(event)

            Success("Successfully published the pvc payload for family with hbx_id #{params[:family_hbx_id]}")
          end

          private

          def validate(params)
            errors = []
            errors << 'application hbx_id is missing' unless params[:application_hbx_id]
            errors << 'family_hbx_id is missing' unless params[:family_hbx_id]

            errors.empty? ? Success(params) : log_error_and_return_failure(errors)
          end

          def fetch_application(params)
            application = ::FinancialAssistance::Application.by_hbx_id(params[:application_hbx_id]).first
            if application.present?
              Success(application)
            else
              pvc_logger.error("No application found with hbx_id #{params[:application_hbx_id]}")
              Failure("No application found with hbx_id #{params[:application_hbx_id]}")
            end
          end

          def create_non_esi_evidences(application)
            application.active_applicants.each do |applicant|
              next if applicant.non_esi_evidence.present?

              applicant.create_evidence(:non_esi_mec, "Non ESI MEC")
            end
            create_evidence_history(application, 'PVC_Submitted', 'PVC - Renewal verifications submitted', 'system')

            Success(true)
          rescue StandardError => e
            pvc_logger.error("Failed to create non_esi_evidences for application with hbx_id #{application.hbx_id} due to #{e.inspect}")
            Failure("Failed to create non_esi_evidences for application with hbx_id #{application.hbx_id}")
          end

          def transform_and_validate_application(application)
            payload_entity = ::Operations::Fdsh::BuildAndValidateApplicationPayload.new.call(application)

            if EnrollRegistry.feature_enabled?(:validate_and_record_publish_application_errors) && payload_entity.failure?
              record_application_failure(application, payload_entity.failure.messages)
              return log_error_and_return_failure(payload_entity.failure.messages)
            end

            if EnrollRegistry.feature_enabled?(:validate_and_record_publish_application_errors) && payload_entity.success?
              valid_applicants = validate_applicants(payload_entity, application)
              return complete_create_pvc_request(valid_applicants, application, payload_entity)
            end

            payload_entity
          rescue StandardError => e
            pvc_logger.error("Failed to transform application with hbx_id #{application.hbx_id} due to #{e.inspect}")
            record_application_failure(application, "transformation failure") if EnrollRegistry.feature_enabled?(:validate_and_record_publish_application_errors)
            Failure("Failed to transform application with hbx_id #{application.hbx_id}")
          end

          def validate_applicants(payload_entity, application)
            applicants_entity = payload_entity.value!.applicants
            results_array = []

            application.active_applicants.map do |eligible_applicant|
              applicant_entity = applicants_entity.detect { |appl_entity| eligible_applicant.person_hbx_id == appl_entity.person_hbx_id }
              result = ::Operations::Fdsh::PayloadEligibility::CheckApplicantEligibilityRules.new.call(applicant_entity, :non_esi_mec)

              if result.success?
                results_array << true
              else
                record_applicant_failure(eligible_applicant.non_esi_evidence, result.failure)
                results_array << false
              end
            end

            results_array
          end

          def complete_create_pvc_request(valid_applicants, application, payload_entity)
            if valid_applicants.any?(true)
              payload_entity
            else
              error_message = "Failed to transform application with hbx_id #{application.hbx_id} due to all applicants being invalid"
              log_error_and_return_failure(error_message)
            end
          end

          def record_application_failure(application, error_messages)
            application.active_applicants.each do |applicant|
              evidence = applicant.non_esi_evidence
              next unless evidence.present?

              record_applicant_failure(evidence, error_messages)
            end
          end

          def record_applicant_failure(evidence, error_messages)
            add_verification_history(evidence, 'PVC_Submission_Failed', "PVC - Periodic verifications submission failed due to #{error_messages}", 'system')
            update_evidence_to_default_state(evidence)
          end

          def add_verification_history(evidence, action, update_reason, update_by)
            evidence.add_verification_history(action, update_reason, update_by) if evidence.present?
          end

          def create_evidence_history(application, action, update_reason, update_by)
            application.active_applicants.each do |applicant|
              evidence = applicant.non_esi_evidence
              next unless evidence.present?
              add_verification_history(evidence, action, update_reason, update_by)
            end
          end

          def update_evidence_to_default_state(evidence)
            evidence&.determine_mec_evidence_aasm_status
          end

          def build_event(cv3_application)
            event('events.fdsh.evidences.periodic_verification_confirmation', attributes: { application: cv3_application.to_h })
          end

          def publish(event)
            event.publish
            Success("Successfully published the pvc payload")
          end

          def pvc_logger
            @pvc_logger ||= Logger.new("#{Rails.root}/log/pvc_non_esi_logger_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
          end

          def log_error_and_return_failure(error)
            pvc_logger.error(error)
            Failure(error)
          end
        end
      end
    end
  end
end
