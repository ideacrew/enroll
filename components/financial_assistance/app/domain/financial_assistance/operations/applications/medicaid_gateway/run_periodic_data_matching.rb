# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'aca_entities/magi_medicaid/libraries/iap_library'

module FinancialAssistance
  module Operations
    module Applications
      module MedicaidGateway
        # Operation to fetch needed families to call Local Medicaid ME service
        # to update application determination eligibility
        class RunPeriodicDataMatching
          include Dry::Monads[:result, :do]
          include EventSource::Command
          include EventSource::Logging

          def call(params)
            values = yield validate(params)
            response = yield filter_and_call_mec_service(values)

            Success(response)
          end

          private

          def validate(params)
            errors = []
            errors << 'assistance_year param missing' if params[:assistance_year].blank?
            assistance_year = params[:assistance_year]
            errors << 'assistance_year param is invalid' unless assistance_year.to_i.to_s == assistance_year.to_s
            errors << 'transmittable_message_id param is missing' if params[:transmittable_message_id].blank?
            batch_size = params[:batch_size]
            errors << 'batch_size param given is invalid' if batch_size.present? && batch_size.to_i > 0

            errors.empty? ? Success(params) : Failure(errors)
          end

          def filter_and_call_mec_service(params)
            initialize_logger
            batch_size = params[:batch_size]&.to_i || 1000
            @total_applications_published = 0
            families = fetch_enrolled_and_renewal_families
            process_families(families, batch_size, params)
            @logger.info "MedicaidGateway::RunPeriodicDataMatching Completed periodic data matching for #{@total_applications_published} applications"
            Success(total_applications_published: @total_applications_published)
          rescue StandardError => e
            @logger.error "Error: message: #{e.message}, backtrace: #{e.backtrace}"
          end

          def initialize_logger
            log_file = "#{Rails.root}/log/run_periodic_data_matching_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
            @logger = Logger.new(log_file)
          end

          def fetch_enrolled_and_renewal_families
            Family.in(_id: HbxEnrollment.by_health.enrolled_and_renewal.distinct(:family_id))
          end

          def process_families(families, batch_size, params)
            (0..families.count).step(batch_size) do |offset|
              batch = families.skip(offset).limit(batch_size)
              process_family_batch(batch, params)
            end
          end

          def process_family_batch(batch, params)
            batch.each do |family|
              enrollments = family.hbx_enrollments.by_health.enrolled_and_renewal
              next unless eligible_for_mec_check?(enrollments)

              determined_application = fetch_application(family, params[:assistance_year])
              next unless determined_application.present?

              process_mec_check(determined_application, params)
            end
          end

          def fetch_application(family, assistance_year)
            applications = ::FinancialAssistance::Application.where(
              family_id: family.id,
              assistance_year: assistance_year,
              aasm_state: 'determined',
              'applicants.is_ia_eligible' => true
            )
            applications.max_by(&:created_at)
          end

          def eligible_for_mec_check?(enrollments)
            enrollments.any? do |enrollment|
              enrollment.applied_aptc_amount.cents.positive? || %w[02 03 04 05 06].include?(enrollment.product.csr_variant_id)
            end
          end

          def process_mec_check(application, params)
            @logger.info "process mec_check for determined application #{application.id}"
            return if params[:skip_mec_call]
            mec_check_published = ::FinancialAssistance::Operations::Applications::MedicaidGateway::RequestMecChecks.new.call(application_id: application.id)
            if mec_check_published.success?
              @total_applications_published += 1
              @logger.info "Successfully published mec_check for determined application #{application.id}"
            else
              @logger.error "Error publishing mec_check for determined application #{application.id}"
            end
          end

          def log_completion
            @logger.info "MedicaidGateway::RunPeriodicDataMatching Completed periodic data matching for #{@total_applications_published} applications"
            Success(total_applications_published: @total_applications_published)
          end

        end
      end
    end
  end
end
