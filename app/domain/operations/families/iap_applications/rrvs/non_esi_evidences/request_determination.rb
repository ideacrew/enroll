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
            include Dry::Monads[:result, :do]
            include EventSource::Command
            include EventSource::Logging

            def call(params)
              values = yield validate(params)
              application = yield fetch_application(values)
              _evidences = yield create_non_esi_evidences(application)
              cv3_application = yield transform_application(application)
              event = yield build_event(cv3_application)
              publish(event)
              create_evidence_history(application)

              Success("Successfully published payload for rrv non esi and created history event")
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
                rrv_logger.info("No applicationfound with hbx_id #{params[:application_hbx_id]}")
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
              rrv_logger.error("Failed to transform application with hbx_id #{application.hbx_id} due to #{e.inspect}")
              Failure("Failed to transform application with hbx_id #{application.hbx_id}")
            end

            def build_event(cv3_application)
              event('events.families.iap_applications.rrvs.non_esi_evidences.determination_requested', attributes: cv3_application.to_h)
            end

            def publish(event)
              event.publish

              Success("Successfully published payload for rrv non esi")
            end

            def create_evidence_history(application)
              application.active_applicants.each do |applicant|
                evidence = applicant.non_esi_evidence
                evidence.add_verification_history('RRV_Submitted', 'RRV - Renewal verifications submitted', 'system')
              end

              application.save
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
