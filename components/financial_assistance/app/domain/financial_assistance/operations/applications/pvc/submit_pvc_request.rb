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

        class SubmitPvcRequest
          include Dry::Monads[:result, :do]
          include EventSource::Command
          include EventSource::Logging

          #@ todo document parameters
          # document the default behaviour of CSR
          def call(params)
            start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
            values = yield validate(params)
            families = find_families(values)
            submit(params, families)
            end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
            seconds_elapsed = end_time - start_time
            hr_min_sec = format("%02dhr %02dmin %02dsec", seconds_elapsed / 3600, seconds_elapsed / 60 % 60, seconds_elapsed % 60)
            Success("Successfully Submitted PVC Set / Total time to complete: #{hr_min_sec}")
          end

          private

          def validate(params)
            errors = []
            errors << 'applications_per_event ref missing' unless params[:applications_per_event]
            errors << 'assistance_year ref missing' unless params[:assistance_year]
            # errors << 'csr_l ref missing' unless params[:csr_list]
            # @ convert the array list to a constant
            params[:csr_list] = ["02", "04", "05", "06"] if params[:csr_list].blank?

            errors.empty? ? Success(params) : Failure(errors)
          end

          def find_families(params)

            #family_ids = FinancialAssistance::Application.where(aasm_state: "determined", assistance_year: params[:assistance_year]).distinct(:family_id)
            #family_ids = Family.with_all_verifications.by_enrollment_individual_market.periodic_verifiable.include_csrs

            # family_ids = FinancialAssistance::Application.where(assistance_year: params[:assistance_year]).is_aptc_or_csr_eligible.enrolled_in_healthplan.csr_included(["02", "04", "05", "06"]).distinct(:family_id)
            
            Family.periodic_verifiable_for_assistance_year(params[:assistance_year], params[:csr_list])
            # @todo change to send and event with this
          end

          def fetch_application(family, assistance_year)
            ::FinancialAssistance::Application.where(assistance_year: assistance_year,
                                                     aasm_state: 'determined',
                                                     family_id: family.id).max_by(&:created_at)
          end

          def transform_and_construct(family, assistance_year)
            application = fetch_application(family, assistance_year)
            payload = FinancialAssistance::Operations::Applications::Transformers::ApplicationTo::Cv3Application.new.call(application)
            AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(payload.value!).value!
          end

          def is_aptc_or_csr_eligible?(application)
            eligibility = application.eligibility_determinations.max_by(&:determined_at)
            eligibility.present? && (eligibility.is_aptc_eligible? || eligibility.is_csr_eligible?)
          end

          def submit(params, families)
            counter = 0
            applications_with_evidences = []
            pvc_logger = Logger.new("#{Rails.root}/log/pvc_logger_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
            pvc_logger.info("********************************* start submitting pvc requests *********************************")
            families.each do |family|
              determined_application = fetch_application(family, params[:assistance_year])
              next unless determined_application.present? && is_aptc_or_csr_eligible?(determined_application)
              determined_application.create_rrv_evidences
              cv3_application = transform_and_construct(family, params[:assistance_year])
              applications_with_evidences << cv3_application.to_h
              counter += 1
              pvc_logger.info("**************** current batch: #{applications_with_evidences.length} , total: #{counter} ************************") if applications_with_evidences.length % 100 == 0
              if applications_with_evidences.length % params[:applications_per_event] == 0
                publish(applications_with_evidences)
                applications_with_evidences = []
              end
            rescue StandardError => e
              pvc_logger.info("failed to process for person with hbx_id #{family.primary_person.hbx_id} due to #{e.inspect}")
            end
            publish(applications_with_evidences) if applications_with_evidences.any?
            pvc_logger.info("*************** end submitting pvc process, total #{counter} applications ***********************")
          end

          def build_event(payload)
            event('events.fdsh.evidences.periodic_verification_confirmation', attributes: { applications: payload })
          end

          def publish(payload)
            event = build_event(payload)
            event.success.publish

            Success("Successfully published the pvc batch")
          end
        end
      end
    end
  end
end
