# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Families
    module IapApplications
      module Rrvs
        module IncomeEvidences
          # This operation is to publish cv3 application for rrv ifsv verification
          class RequestDetermination
            include Dry::Monads[:do, :result]
            include EventSource::Command
            include EventSource::Logging

            def call(params)
              values = yield validate(params)
              application = yield fetch_application(values)
              _evidences = yield create_income_evidences(application)
              cv3_application = yield transform_and_validate_application(application)
              event = yield build_event(cv3_application)
              publish(event)

              Success("Successfully published payload for rrv ifsv and created history event")
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

            def create_income_evidences(application)
              application.active_applicants.each do |applicant|
                next if applicant.income_evidence.present?

                applicant.create_eligibility_income_evidence
              end

              create_evidence_history(application, 'RRV_Submitted', 'RRV - Renewal verifications submitted', 'system')
              Success(true)
            end

            def transform_and_validate_application(application)
              payload_entity = Operations::Fdsh::BuildAndValidateApplicationPayload.new.call(application)
              return payload_entity unless EnrollRegistry.feature_enabled?(:validate_and_record_publish_application_errors)

              if payload_entity.success?
                result = validate_applicants(payload_entity)
                if result.any?(Failure)
                  errors = result.select { |r| r.is_a?(Failure) }.map(&:failure)
                  record_application_failure(application, errors)
                  return Failure(errors)
                end
              elsif payload_entity.failure?
                record_application_failure(application, payload_entity.failure.messages)
              end

              payload_entity
            rescue StandardError => e
              rrv_logger.error("Failed to transform application with hbx_id #{application.hbx_id} due to #{e.inspect}")
              Failure("Failed to transform application with hbx_id #{application.hbx_id}")
            end

            def validate_applicants(payload_entity)
              payload_entity.value!.applicants.collect do |applicant_entity|
                Operations::Fdsh::PayloadEligibility::CheckApplicantEligibilityRules.new.call(applicant_entity, :income)
              end.flatten.compact
            end

            def record_application_failure(application, error_messages)
              create_evidence_history(application, 'RRV_Submission_Failed', "RRV - Renewal verifications submission failed due to #{error_messages}", 'system')
              update_evidence_state_for_all_applicants(application)
            end

            def build_event(cv3_application)
              event('events.families.iap_applications.rrvs.income_evidences.determination_requested', attributes: { application: cv3_application.to_h })
            end

            def publish(event)
              event.publish

              Success("Successfully published payload for rrv ifsv")
            end

            def create_evidence_history(application, action, update_reason, update_by)
              application.active_applicants.each do |applicant|
                evidence = applicant.income_evidence
                next unless evidence.present?
                evidence.add_verification_history(action, update_reason, update_by)
              end
            end

            def update_evidence_state_for_all_applicants(application)
              application.active_applicants.each do |applicant|
                update_income_evidence_to_default_state(applicant.income_evidence)
              end
            end

            # update income evidence state to default aasm state for applicant
            def update_income_evidence_to_default_state(income_evidence)
              income_evidence&.determine_income_evidence_aasm_status
            end

            def rrv_logger
              @rrv_logger ||= Logger.new("#{Rails.root}/log/rrv_ifsv_logger_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
            end
          end
        end
      end
    end
  end
end
