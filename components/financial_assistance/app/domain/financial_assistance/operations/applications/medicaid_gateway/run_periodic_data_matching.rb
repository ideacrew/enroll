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
            errors << 'transmittable_job_id param is missing' if params[:transmittable_job_id].blank?

            errors.empty? ? Success(params) : Failure(errors)
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

          def filter_and_call_mec_service(params)
            @logger = Logger.new("#{Rails.root}/log/run_periodic_data_matching_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
            batch_size = params[:batch_size] || 1000
            families = Family.where(:_id.in => HbxEnrollment.by_health.enrolled_and_renewal.distinct(:family_id))
            total_families_count = families.count

            @logger.info "MedicaidGateway::RunPeriodicDataMatching Total families to run - #{total_families_count}"
            total_applications_ran = 0
            (0..total_families_count).step(batch_size) do |offset|
              batch = families.skip(offset).limit(batch_size)
              batch.each do |family|
                enrollments = family.hbx_enrollments.by_health.enrolled_and_renewal
                # Process each record in the batch
                next unless enrollments.any? {|enrollment| enrollment.applied_aptc_amount.cents.positive? || %w[02 03 04 05 06].include?(enrollment.product.csr_variant_id) }
                determined_application = fetch_application(family, params[:assistance_year])
                next unless determined_application.present?
                total_applications_ran += 1
                ::FinancialAssistance::Operations::Applications::MedicaidGateway::RequestMecChecks.new.call(application_id: determined_application.id) unless params[:skip_mec_call]
              end
            end
            @logger.info "MedicaidGateway::RunPeriodicDataMatching Completed periodic data matching for #{total_applications_ran} applications"
            Success({ total_applications_ran: total_applications_ran })
          rescue StandardError => e
            @logger.error "Error: message: #{e.message}, backtrace: #{e.backtrace}"
          end

        end
      end
    end
  end
end
