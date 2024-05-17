# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'aca_entities/magi_medicaid/libraries/iap_library'

module FinancialAssistance
  module Operations
    module Applications
      module Rrv
        # operation to manually trigger rrv events.
        # It will take families as input and find the determined application, add evidences and publish the group of applications
        class CreateRrvRequest
          include Dry::Monads[:do, :result]
          include EventSource::Command
          include EventSource::Logging

          def call(params)
            values = yield validate(params)
            applications = yield collect_applications_from_families(values)
            event = yield build_event(applications)
            result = yield publish(event)

            Success(result)
          end

          private

          def validate(params)
            errors = []
            errors << 'families ref missing' unless params[:families]
            errors << 'assistance_year ref missing' unless params[:assistance_year]

            errors.empty? ? Success(params) : Failure(errors)
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
            application.aptc_applicants.present?
          end

          def collect_applications_from_families(params)
            applications_with_evidences = []
            count = 0
            rrv_logger = Logger.new("#{Rails.root}/log/rrv_logger_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")

            params[:families].no_timeout.each do |family|
              determined_application = fetch_application(family, params[:assistance_year])
              next unless determined_application.present? && is_aptc_or_csr_eligible?(determined_application)

              determined_application.create_rrv_evidences
              cv3_application = transform_and_construct(family, params[:assistance_year])
              applications_with_evidences << cv3_application.to_h
              determined_application.create_rrv_evidence_histories
              count += 1
              rrv_logger.info("********************************* processed #{count}*********************************") if count % 100 == 0
            rescue StandardError => e
              rrv_logger.info("failed to process for person with hbx_id #{family.primary_person.hbx_id} due to #{e.inspect}")
            end

            applications_with_evidences.present? ? Success(applications_with_evidences) : Failure("No Determined applications with ia_eligible applicants")
          end

          def build_event(payload)
            event('events.iap.applications.magi_medicaid_application_renewal_assistance_eligible', attributes: { applications: payload })
          end

          def publish(event)
            event.publish

            Success("Successfully published the rrv payload")
          end
        end
      end
    end
  end
end