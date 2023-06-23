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
          include Dry::Monads[:result, :do]
          include EventSource::Command
          include EventSource::Logging
          include FinancialAssistance::JobsHelper

          def call(params)
            values = yield validate(params)
            application = yield fetch_application(values)
            _evidences = yield create_non_esi_evidences(application)
            cv3_application = yield transform_application(application)
            event = yield build_event(cv3_application)
            publish(event)
            create_evidence_history(application)

            Success("Successfully published the pvc payload for family with hbx_id #{params[:family_hbx_id]}")
          end

          private

          def validate(params)
            errors = []
            errors << 'application hbx_id is missing' unless params[:application_hbx_id]
            errors << 'family_hbx_id is missing' unless params[:family_hbx_id]

            errors.empty? ? Success(params) : Failure(errors)
          end

          def fetch_application(params)
            application = ::FinancialAssistance::Application.by_hbx_id(params[:application_hbx_id]).first
            if application.present?
              Success(application)
            else
              pvc_logger.error("No applicationfound with hbx_id #{params[:application_hbx_id]}")
              Failure("No applicationfound with hbx_id #{params[:application_hbx_id]}")
            end
          end

          def create_non_esi_evidences(application)
            application.active_applicants.each do |applicant|
              next if applicant.non_esi_evidence.present?

              applicant.create_evidence(:non_esi_mec, "Non ESI MEC")
            end

            Success(true)
          end

          def transform_application(application)
            payload = ::FinancialAssistance::Operations::Applications::Transformers::ApplicationTo::Cv3Application.new.call(application)
            AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(payload.value!)
          rescue StandardError => e
            pvc_logger.error("Failed to transform application with hbx_id #{application.hbx_id} due to #{e.inspect}")
            Failure("Failed to transform application with hbx_id #{application.hbx_id}")
          end

          def build_event(cv3_application)
            event('events.fdsh.evidences.periodic_verification_confirmation', attributes: { application: cv3_application.to_h })
          end

          def publish(event)
            event.publish
            Success("Successfully published the pvc payload")
          end

          def create_evidence_history(application)
            application.active_applicants.each do |applicant|
              evidence = applicant.non_esi_evidence
              evidence&.add_verification_history('PVC_Submitted', 'PVC - Renewal verifications submitted', 'system')
            end

            application.save
          end

          def pvc_logger
            @pvc_logger ||= Logger.new("#{Rails.root}/log/pvc_non_esi_logger_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
          end
        end
      end
    end
  end
end