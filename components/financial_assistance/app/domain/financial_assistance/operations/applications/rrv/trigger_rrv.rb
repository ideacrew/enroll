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
        class TriggerRrv
          include Dry::Monads[:result, :do]
          include EventSource::Command
          include EventSource::Logging

          def call(params)
            applications = collect_applications_from_families(params[:families])
            event = yield build_event(applications)
            result = yield publish(event)

            Success(result)
          end

          private

          def fetch_application(family)
            ::FinancialAssistance::Application.where(family_id: family.id,
                                                     assistance_year: TimeKeeper.date_of_record.next_year.year,
                                                     aasm_state: 'determined').max_by(&:created_at)
          end

          def build_evidences(types, applicant)
            types.collect do |type|
              key, title = type

              next if applicant.evidences.by_name(key).present?
              case key
              when :non_esi_mec
                next unless applicant.is_ia_eligible? || applicant.is_applying_coverage
                FinancialAssistance::Evidence.new(key: key, title: title, eligibility_status: "attested")
              when :income
                next unless active_applicants.any?(&:is_ia_eligible?) || active_applicants.any?(:is_applying_coverage)
                FinancialAssistance::Evidence.new(key: key, title: title, eligibility_status: "outstanding")
              end
            end
          end

          def create_evidences(application)
            types = []
            types << [:non_esi_mec, "Non ESI MEC"] if FinancialAssistanceRegistry.feature_enabled?(:non_esi_mec_determination)
            types << [:income, "Income"] if FinancialAssistanceRegistry.feature_enabled?(:ifsv_determination)

            application.active_applicants.each { |app| app.evidences = build_evidences(types, app) }
            application.save!
            application
          end

          def transform_and_construct(application)
            payload = FinancialAssistance::Operations::Applications::Transformers::ApplicationTo::Cv3Application.new.call(application)
            AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(payload.value!).value!
          end

          def collect_applications_from_families(families)
            applications_with_evidences = []
            count = 0
            rrv_logger = Logger.new("#{Rails.root}/log/rrv_logger_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")

            families.no_timeout.each do |family|
              determined_application = fetch_application(family)
              next unless determined_application.present?

              application = create_evidences(determined_application)
              cv3_application = transform_and_construct(application)

              applications_with_evidences << cv3_application.to_h
              count += 1
              rrv_logger.info("********************************* processed #{count}*********************************") if count % 100 == 0
              applications_with_evidences
            rescue StandardError
              rrv_logger.info("failed to process fpr person with hbx_id #{family.primary_person.hbx_id}")
            end


            applications_with_evidences
          end

          def build_event(payload)
            event('events.fdsh.iap.applications.magi_medicaid_application_renewal_assistance_eligible', attributes: { applications: payload })
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