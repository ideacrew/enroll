# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'aca_entities/magi_medicaid/libraries/iap_library'
require 'csv'

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
            errors << 'batch_size param given is invalid' if batch_size.present? && batch_size.to_i <= 0
            fetch_family_limit = params[:fetch_family_limit]
            errors << 'fetch_family_limit param given is invalid' if fetch_family_limit.present? && fetch_family_limit.to_i <= 0
            errors.empty? ? Success(params) : Failure(errors)
          end

          def filter_and_call_mec_service(params)
            initialize_logger
            batch_size = params[:batch_size]&.to_i || 1000
            @total_applications_published = 0
            families = fetch_enrolled_and_renewal_families(params)
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

          def fetch_enrolled_and_renewal_families(params)
            if params[:fetch_family_limit].present?
              # can be very helpful in UAT testing where we can process few families, test the behaviour, process rest of them
              Family.in(_id: HbxEnrollment.by_health.enrolled_and_renewal.limit(params[:fetch_family_limit]).distinct(:family_id))
            else
              Family.in(_id: HbxEnrollment.by_health.enrolled_and_renewal.distinct(:family_id))
            end
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
              build_csv_report(family, enrollments, determined_application) # Build CSV report
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

          def build_csv_report(family, enrollments, determined_app)
            file_path = "#{Rails.root}/periodic_data_matching_results_me.csv"
            File.delete(file_path) if File.exist?(file_path)
            add_csv_headers(file_path)
            # add data to csv
            CSV.open(file_path, 'a') do |csv|
              enrollments.each do |enr|
                enr.hbx_enrollment_members.each do |enr_member|
                  fm = enr_member.family_member
                  applicant = determined_app&.active_applicants&.where(family_member_id: fm.id)&.first
                  program_eligibility = fetch_eligibility(applicant)
                  csv << [
                    family.hbx_assigned_id,
                    fm.person&.hbx_id,
                    fm.is_primary_applicant,
                    enr.hbx_id,
                    enr.coverage_kind,
                    enr.aasm_state,
                    enr.product.hios_id,
                    enr.applied_aptc_amount.to_s,
                    program_eligibility
                  ]
                end
              end
            end
          rescue StandardError => e
            @logger.error "Error: message: application: #{determined_app.id}, #{e.message}, backtrace: #{e.backtrace}"
          end

          def add_csv_headers(file_path)
            # Check if the file is empty or missing headers
            return if File.exist?(file_path) && !File.zero?(file_path)
            CSV.open(file_path, 'w') do |csv|
              csv << fetch_csv_headers
            end
          end

          def fetch_csv_headers
            %w[FamilyHbxID MemberHbxId IsPrimaryApplicant EnrollmentHbxId EnrollmentType EnrollmentState HiosId AppliedAptc ProgramEligibility]
          end

          def fetch_eligibility(applicant)
            if applicant.present?
              if applicant.is_ia_eligible
                "IA Eligible"
              elsif applicant.is_medicaid_chip_eligible
                "Medicaid Chip Eligible"
              elsif is_non_magi_medicaid_eligible
                "Non Magi Medicaid Eligible"
              elsif applicant.is_totally_ineligible
                "Totally Ineligible"
              elsif applicant.is_without_assistance
                "Without Assistance"
              else
                ""
              end
            else
              "applicant not found in faa application"
            end
          end

          def process_mec_check(application, params)
            @logger.info "process mec_check for determined application #{application.id}"
            return if params[:skip_mec_call]
            mec_check_published = publish_mec_check(application.id)
            if mec_check_published.success?
              @total_applications_published += 1
              @logger.info "Successfully published mec_check for determined application #{application.id}"
            else
              @logger.error "Error publishing mec_check for determined application #{application.id}"
            end
          end

          def publish_mec_check(application_id)
            ::FinancialAssistance::Operations::Applications::MedicaidGateway::RequestMecChecks.new.call(application_id: application_id)
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
