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
            applications = yield collect_applications_from_families(params[:families])
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

          # rubocop:disable Metrics/CyclomaticComplexity
          def build_evidences(types, applicant, application)
            types.each do |type|
              key, title = type
              case key
              when :non_esi
                next unless applicant.is_ia_eligible? || applicant.is_applying_coverage
                applicant.send("build_#{key}_evidence", key: key, title: title) if applicant.send("#{key}_evidence").blank?
              when :income
                next unless application.active_applicants.any?(&:is_ia_eligible?) || application.active_applicants.any?(&:is_applying_coverage)
                applicant.build_income_evidence(key: key, title: title) if applicant.income_evidence.blank?
                applicant.income_evidence.move_to_pending! if  applicant.incomes.present?
              end
            rescue StandardError => e
              Rails.logger.error("unable to create #{key} evidence for applicant #{applicant.id} due to #{e.inspect}")
            end
          end
          # rubocop:enable Metrics/CyclomaticComplexity

          def create_evidences(application)
            types = []
            types << [:non_esi, "Non ESI MEC"] if FinancialAssistanceRegistry.feature_enabled?(:non_esi_mec_determination)
            types << [:income, "Income"] if FinancialAssistanceRegistry.feature_enabled?(:ifsv_determination)

            application.active_applicants.each do |applicant|
              build_evidences(types, applicant, application)
              applicant.save!
            end
          end

          def transform_and_construct(family)
            application = fetch_application(family)
            payload = FinancialAssistance::Operations::Applications::Transformers::ApplicationTo::Cv3Application.new.call(application)
            AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(payload.value!).value!
          end

          def collect_applications_from_families(families)
            applications_with_evidences = []
            count = 0
            rrv_logger = Logger.new("#{Rails.root}/log/rrv_logger_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")

            families.each do |family|
              determined_application = fetch_application(family)
              next unless determined_application.present?
              create_evidences(determined_application)
              cv3_application = transform_and_construct(family)
              applications_with_evidences << cv3_application.to_h
              count += 1
              rrv_logger.info("********************************* processed #{count}*********************************") if count % 100 == 0
            rescue StandardError => e
              rrv_logger.info("failed to process for person with hbx_id #{family.primary_person.hbx_id} due to #{e.inspect}")
            end

            applications_with_evidences.present? ? Success(applications_with_evidences) : Failure("No Applications for given families")
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