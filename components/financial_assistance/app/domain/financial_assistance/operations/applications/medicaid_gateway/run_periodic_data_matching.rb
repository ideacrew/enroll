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
            ::FinancialAssistance::Application.where(assistance_year: assistance_year,
                                                     aasm_state: 'determined',
                                                     family_id: family.id).max_by(&:created_at)
          end

          def filter_and_call_mec_service(params)
            batch_size = params[:batch_size] || 1000
            determined_family_ids = FinancialAssistance::Application.where(:aasm_state => "determined",
                                                                :assistance_year => params[:assistance_year],
                                                                :"applicants.is_ia_eligible" => true).distinct(:family_id)

            Rails.logger.info "MedicaidGateway::RunPeriodicDataMatching Total families determined - #{determined_family_ids.count}"
            not_outstanding_families = Family.where(:_id.in => determined_family_ids, :'eligibility_determination.outstanding_verification_status'.nin => %w[outstanding not_enrolled])
            Rails.logger.info "MedicaidGateway::RunPeriodicDataMatching Total number of not outstanding families - #{not_outstanding_families.count}"
            total_applications_ran = 0
            (0..not_outstanding_families.count).step(batch_size) do |offset|
              batch = not_outstanding_families.skip(offset).limit(batch_size)
              batch.each do |family|
                # Process each record in the batch

                next unless family.hbx_enrollments.enrolled_and_renewal.any? {|enrollment| enrollment.applied_aptc_amount > 0 || %w[02 03 04 05 06].include?(enrollment.product.csr_variant_id) }
                determined_application = fetch_application(family, params[:assistance_year])
                next unless determined_application.present? && is_aptc_or_csr_eligible?(determined_application)
                total_applications_ran += 1
                ::FinancialAssistance::Operations::Applications::MedicaidGateway::RequestMecChecks.new.call(application_id: determined_application.id)
              end
            end
            Rails.logger.info "MedicaidGateway::RunPeriodicDataMatching Total applications ran periodic data matching - #{total_applications_ran}"
            Success({ total_applications_ran: total_applications_ran })
          end

          def is_aptc_or_csr_eligible?(application)
            application.aptc_applicants.present?
          end

        end
      end
    end
  end
end
