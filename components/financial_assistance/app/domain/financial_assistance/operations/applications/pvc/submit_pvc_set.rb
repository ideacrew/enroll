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
        class SubmitPvcSet
          include Dry::Monads[:result, :do]
          include EventSource::Command
          include EventSource::Logging
          include FinancialAssistance::JobsHelper

          PVC_CSR_LIST = ['02', '04', '05', '06'].freeze

          # @param [Int] assistance_year
          # @param [Array] csr_list
          # @param [Int] families_per_event
          # @param [Int] skip
          # @return [ Success ] Job successfully completed
          def call(params)
            values = yield validate(params)
            family_ids = find_families(values)
            submit(params, family_ids)

            Success("Successfully Submitted PVC Set")
          end

          private

          def validate(params)
            errors = []
            errors << 'assistance_year ref missing' unless params[:assistance_year]
            params[:csr_list] = PVC_CSR_LIST if params[:csr_list].blank?
            errors.empty? ? Success(params) : log_error_and_return_failure(errors)
          end

          def find_families(params)
            if EnrollRegistry.feature_enabled?(:temporary_configuration_enable_multi_tax_household_feature)
              Family.with_applied_aptc_or_csr_active_enrollments(params[:csr_list]).distinct(:_id)
            else
              Family.periodic_verifiable_for_assistance_year(params[:assistance_year], params[:csr_list]).distinct(:_id)
            end
          end

          def fetch_application(family, assistance_year)
            applications = ::FinancialAssistance::Application.where(family_id: family.id,
                                                                    assistance_year: assistance_year,
                                                                    aasm_state: 'determined',
                                                                    "applicants.is_ia_eligible": true)


            applications.max_by(&:submitted_at)
          end

          def submit(params, family_ids)
            families = Family.where(:_id.in => family_ids)
            count = 0

            families.no_timeout.each do |family|
              determined_application = fetch_application(family, params[:assistance_year])

              if determined_application.present?
                publish({family_hbx_id: family.hbx_assigned_id, application_hbx_id: determined_application.hbx_id, assistance_year: params[:assistance_year]})
                count += 1
                pvc_logger.info("********************************* processed #{count} families *********************************") if count % 100 == 0
              else
                pvc_logger.error("No Determined application found for family with primary person hbx_id #{family.primary_person.hbx_id}")
              end
            rescue StandardError => e
              pvc_logger.error("failed to process for person with hbx_id #{family.primary_person.hbx_id} due to #{e.inspect}")
            end
          end

          def build_event(payload)
            event('events.iap.applications.request_family_pvc_determination', attributes: payload)
          end

          def publish(payload)
            event = build_event(payload)
            event.success.publish

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
