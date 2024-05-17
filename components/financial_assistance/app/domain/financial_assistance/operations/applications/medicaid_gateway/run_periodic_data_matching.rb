# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'aca_entities/magi_medicaid/libraries/iap_library'
require "#{Rails.root}/lib/decorators/build_report"
require "#{Rails.root}/lib/decorators/csv_file_builder"
require 'csv'

module FinancialAssistance
  module Operations
    module Applications
      module MedicaidGateway
        # Operation to fetch needed families to call Local Medicaid ME service
        # to update application determination eligibility
        class RunPeriodicDataMatching
          include Dry::Monads[:do, :result]
          include EventSource::Command
          include EventSource::Logging

          def call(params)
            values = yield validate(params)
            @logger = initialize_logger
            csv_file_builder = ::Decorators::CSVFileBuilder.new("#{Rails.root}/periodic_data_matching_results_me_#{Time.now.to_i}.csv", fetch_csv_headers, @logger)
            @report = ::Decorators::BuildReport.new(csv_file_builder)
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
            errors.empty? ? Success(params) : Failure(errors)
          end

          def initialize_logger
            log_file = "#{Rails.root}/log/run_periodic_data_matching_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
            Logger.new(log_file)
          end

          def filter_and_call_mec_service(params)
            batch_size = params[:batch_size]&.to_i || 1000
            @total_applications_published = 0
            families = fetch_enrolled_and_renewal_families(params)
            process_families(families, batch_size, params)
            @logger.info "MedicaidGateway::RunPeriodicDataMatching Completed periodic data matching for #{@total_applications_published} applications"
            Success(total_applications_published: @total_applications_published)
          rescue StandardError => e
            @logger.error "Error in filter_and_call_mec_service with message: #{e.message}, backtrace: #{e.backtrace}"
          end

          def fetch_enrolled_and_renewal_families(params)
            if params[:primary_person_hbx_ids].present?
              # can be very helpful in UAT testing to trigger specific families
              people = Person.where(:hbx_id.in => params[:primary_person_hbx_ids])
              family_ids = people.map(&:primary_family).pluck(:id)
              Family.where(:_id.in => family_ids)
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
            batch.no_timeout.each do |family|
              enrollments = family.hbx_enrollments.by_health.enrolled_and_renewal
              next unless eligible_for_mec_check?(enrollments)

              determined_application = fetch_application(family, params[:assistance_year])
              next unless determined_application.present?
              create_mec_evidence_if_needed(determined_application)
              append_to_csv = params[:skip_mec_call] || process_mec_check(determined_application, params)
              append_data_to_csv(family, enrollments, determined_application) if append_to_csv
            end
          end

          def create_mec_evidence_if_needed(application)
            application.active_applicants.each do |applicant|
              next if applicant.local_mec_evidence.present?

              applicant.create_evidence(:local_mec, "Local MEC")
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

          def append_data_to_csv(family, enrollments, determined_app)
            data_to_append = []
            enrollments.each do |enr|
              enr.hbx_enrollment_members.each do |enr_member|
                fm = enr_member.family_member
                applicant = determined_app&.active_applicants&.where(family_member_id: fm.id)&.first
                program_eligibility = fetch_eligibility(applicant)
                data_to_append << [
                  determined_app.hbx_id,
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
            @report.append_data(data_to_append) if data_to_append.present?
          rescue StandardError => e
            @logger.error "Error: Failed to append data to CSV: application: #{determined_app.id}, #{e.message}, backtrace: #{e.backtrace}"
          end

          def fetch_csv_headers
            %w[ApplicationHBXID FamilyHbxID MemberHbxId IsPrimaryApplicant EnrollmentHbxId EnrollmentType EnrollmentState HiosId AppliedAptc ProgramEligibility]
          end

          def fetch_eligibility(applicant)
            if applicant.present?
              if applicant.is_ia_eligible
                "IA Eligible"
              elsif applicant.is_medicaid_chip_eligible
                "Medicaid Chip Eligible"
              elsif applicant.is_non_magi_medicaid_eligible
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
            mec_check_published = publish_mec_check(application.id, params)
            if mec_check_published.success?
              @total_applications_published += 1
              @logger.info "Successfully published mec_check for determined application #{application.id}"
              true
            else
              @logger.error "Error publishing mec_check for determined application #{application.id}"
              false
            end
          end

          def publish_mec_check(application_id, params)
            ::FinancialAssistance::Operations::Applications::MedicaidGateway::RequestMecChecks.new.call(application_id: application_id, transmittable_message_id: params[:transmittable_message_id])
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
