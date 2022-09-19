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

          # "02", "04", "05", "06" are already converted
          PVC_CSR_LIST = [100, 73, 87, 94].freeze

          # @param [Int] applications_per_event
          # @param [Int] assistance_year
          # @param [Array] csr_list
          # @return [ Success ] Job successfully completed
          def call(params)
            start_time = process_start_time
            values = yield validate(params)
            families = find_families(values)
            submit(params, families)
            end_time = process_end_time_formatted(start_time)
            logger.info "Successfully submitted #{families.count} families for PVC in #{end_time}"
            Success("Successfully Submitted PVC Set")
          end

          private

          def validate(params)
            errors = []
            errors << 'applications_per_event ref missing' unless params[:applications_per_event]
            errors << 'assistance_year ref missing' unless params[:assistance_year]
            params[:csr_list] = PVC_CSR_LIST if params[:csr_list].blank?
            errors.empty? ? Success(params) : Failure(errors)
          end

          def find_families(params)
            family_ids = Family.periodic_verifiable_for_assistance_year(params[:assistance_year], params[:csr_list]).distinct(:_id)
            Family.where(:_id.in => family_ids).all
          end

          def submit(params, families)
            skip = params[:skip] || 0
            applications_per_event = params[:applications_per_event]

            while skip < families.count
              criteria = families.skip(skip).limit(applications_per_event)
              publish({families: criteria.pluck(:id), assistance_year: params[:assistance_year]})
              puts "Total number of records processed #{skip + criteria.pluck(:id).length}"
              skip += applications_per_event

              break if params[:max_applications].present? && params[:max_applications] > skip
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
        end
      end
    end
  end
end
