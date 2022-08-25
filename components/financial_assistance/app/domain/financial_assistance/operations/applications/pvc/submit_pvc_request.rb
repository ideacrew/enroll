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

          def call(params)
            values = yield validate(params)
            families = find_families(values)
            submit(params, families)

            Success('Successfully Submitted PVC Set')
          end

          private

          def validate(params)
            errors = []
            errors << 'applications_per_event ref missing' unless params[:applications_per_event]
            errors << 'assistance_year ref missing' unless params[:assistance_year]

            errors.empty? ? Success(params) : Failure(errors)
          end

          def find_families(params)
            family_ids = FinancialAssistance::Application.where(aasm_state: "determined", assistance_year: params[:assistance_year]).distinct(:family_id)
            Family.where(:_id.in => family_ids).all
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
            applications_with_evidences = []
            count = 0
            pvc_logger = Logger.new("#{Rails.root}/log/pvc_logger_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
            pvc_logger.info("********************************* start submitting pvc requests *********************************") 

            families.each do |family|
                determined_application = fetch_application(family, params[:assistance_year])
                next unless determined_application.present? && is_aptc_or_csr_eligible?(determined_application)
                determined_application.create_rrv_evidences
                cv3_application = transform_and_construct(family, params[:assistance_year])
                applications_with_evidences << cv3_application.to_h
                count += 1
                rrv_logger.info("********************************* processed #{count}*********************************") if count % 100 == 0

                if count % params[:applications_per_event] == 0
                  publish(applications_with_evidences)
                  applications_with_evidences = []
                end
            end
            if applications_with_evidences.any?
                publish(applications_with_evidences)
            end
            pvc_logger.info("********************************* end submitting pvc requests *********************************") if count % 100 == 0

            # skip = params[:skip] || 0
            # applications_per_event = params[:applications_per_event]

            # while skip < families.count
            #   criteria = families.skip(skip).limit(applications_per_event)
            #   publish({families: criteria.pluck(:id), assistance_year: params[:assistance_year]})
            #   puts "Total number of records processed #{skip + criteria.pluck(:id).length}"
            #   skip += applications_per_event

            #   break if params[:max_applications].present? && params[:max_applications] > skip
            # end
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
