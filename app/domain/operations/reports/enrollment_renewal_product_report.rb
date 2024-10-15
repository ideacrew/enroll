# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Reports
    # Generates a report for enrollments and renewal with product details
    # Operations::Reports::EnrollmentRenewalProductReport.new.call({current_year: 2024})
    class EnrollmentRenewalProductReport
      include Dry::Monads[:result, :do]

      def call(params)
        values            = yield validate(params)
        enrollments       = yield fetch_enrollments(values)
        report_status     = yield generate_report(enrollments, values[:current_year])

        Success(report_status)
      end

      private

      def validate(params)
        Failure('Missing start_date') if params[:current_year].blank?

        Success(params)
      end

      def fetch_enrollments(values)
        enrollments = ::HbxEnrollment.by_year(values[:current_year]).where(
          :aasm_state.in => (HbxEnrollment::ENROLLED_STATUSES - ["coverage_renewed", "coverage_termination_pending"])
        )
        Failure("No enrollments found for year: #{values[:current_year]}") if enrollments.blank?
        Success(enrollments)
      end

      def fetch_notice_report_file_name
        "#{Rails.root}/enrollment_renewal_product_report_#{TimeKeeper.date_of_record.strftime('%Y%m%d')}.csv"
      end

      def fetch_notice_report_headers
        %w[
            Primary_person_Hbx_ID
            2024_Enrollment_Hbx_ID
            2024_Product_Hios_Base_ID
            2025_Renewal_Product_Hios_Base_ID
            2025_Enrollment_Hbx_ID
            2025_Product_Hios_Base_ID
            County_Name_of_the_Rating_Address
          ]
      end

      # rubocop:disable Metrics/CyclomaticComplexity
      def generate_report(enrollments, current_year)
        CSV.open(fetch_notice_report_file_name, 'w+', headers: true) do |csv|
          csv << fetch_notice_report_headers
          enrollment_count = enrollments.count
          puts "Generating report for #{enrollment_count} enrollments"
          batch_size = 1000
          offset = 0
          renewal_year = current_year + 1
          while offset < enrollment_count
            enrollments.offset(offset).limit(batch_size).no_timeout.each do |enrollment|
              renewal_enrollment = ::HbxEnrollment.by_year(renewal_year).where(predecessor_id: enrollment.id).first
              next if renewal_enrollment.blank?

              family = enrollment.family
              primary_hbx_id = family&.primary_applicant&.person&.hbx_id
              enr_hbx_id = enrollment.hbx_id

              enr_product = enrollment&.product
              enr_base_hios_id = enr_product&.hios_base_id
              renewal_product = enrollment&.renewal_product
              renewal_product_hios_id = renewal_product&.hios_base_id

              renewal_enr_hbx_id = renewal_enrollment.hbx_id
              renewal_enr_product = renewal_enrollment.product
              renewal_enr_product_hios_id = renewal_enr_product&.hios_base_id

              county = enrollment.consumer_role&.rating_address&.county

              csv << [primary_hbx_id, enr_hbx_id, enr_base_hios_id, renewal_product_hios_id, renewal_enr_hbx_id, renewal_enr_product_hios_id, county]
            rescue StandardError => e
              Failure("Error raised while processing enrollment with id: #{enrollment_id}, error_message: #{e.message}, backtrace: #{e.backtrace}")
            end

            offset += batch_size
            puts "Processed #{offset} enrollments"
          end

          Success("Generated enrollments report successfully")
        end
      end
      # rubocop:enable Metrics/CyclomaticComplexity
    end
  end
end