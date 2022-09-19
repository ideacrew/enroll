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
            start_time = process_start_time
            values = yield validate(params)
            applications = yield collect_applications_from_families(values)
            event = yield build_event(applications)
            result = yield publish(event)
            end_time = process_end_time_formatted(start_time)
            logger.info "Successfully created PVC request for #{params[:families].count} families for PVC in #{end_time}"
            Success(result)
          end

          private

          def validate(params)
            errors = []
            errors << 'families ref missing' unless params[:families]
            errors << 'assistance_year ref missing' unless params[:assistance_year]

            errors.empty? ? Success(params) : Failure(errors)
          end

          def fetch_application(family, year)
            ::FinancialAssistance::Application.where(assistance_year: year,
                                                     aasm_state: 'determined',
                                                     family_id: family.id).max_by(&:created_at)
          end

          def transform_and_construct(family, assistance_year)
            application = fetch_application(family, assistance_year)
            payload = FinancialAssistance::Operations::Applications::Transformers::ApplicationTo::Cv3Application.new.call(application)
            AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(payload.value!).value!
          end

          def collect_applications_from_families(params)
            applications_with_evidences = []
            count = 0
            pvc_logger = Logger.new("#{Rails.root}/log/pvc_logger_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")

            params[:families].no_timeout.each do |family|
              determined_application = fetch_application(family, params[:assistance_year])
              determined_application.create_rrv_evidences
              cv3_application = transform_and_construct(family, params[:assistance_year])
              applications_with_evidences << cv3_application.to_h
              count += 1
              pvc_logger.info("********************************* processed #{count}*********************************") if count % 100 == 0
            rescue StandardError => e
              pvc_logger.info("failed to process for person with hbx_id #{family.primary_person.hbx_id}/family_id #{family.id}/year #{params[:assistance_year]} due to #{e.inspect}")
            end

            applications_with_evidences.present? ? Success(applications_with_evidences) : Failure("No Applications for given families")
          end

          def build_event(payload)
            event('events.fdsh.evidences.periodic_verification_confirmation', attributes: { applications: payload })
          end

          def publish(event)
            event.publish

            Success("Successfully published the pvc payload")
          end
        end
      end
    end
  end
end