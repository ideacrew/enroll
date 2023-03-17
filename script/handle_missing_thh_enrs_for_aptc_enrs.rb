# frozen_string_literal: true

# Creates TaxHousehold Enrollment objects for 2022 health Enrollments(not in aasm_state 'coverage_canceled', 'shopping') with applied aptc > 0

# bundle exec rails runner script/handle_missing_thh_enrs_for_aptc_enrs.rb

require 'csv'

# rubocop:disable Metrics/AbcSize, Metrics/MethodLength
def process_enrollments(enrollments, field_names, file_name)
  CSV.open(file_name, 'w', force_quotes: true) do |csv|
    csv << field_names
    counter = 0

    enrollments.each do |enrollment|
      family = enrollment.family
      tax_household_enrollments = TaxHouseholdEnrollment.where(enrollment_id: enrollment.id)
      counter += 1

      thh_enrs_newly_created = tax_household_enrollments.blank?

      if tax_household_enrollments.blank?
        find_aptc = ::Operations::PremiumCredits::FindAptc.new.call(
          {
            hbx_enrollment: enrollment,
            effective_on: enrollment.effective_on
          }
        )

        if find_aptc.failure?
          errors = if find_aptc.failure.is_a?(Dry::Validation::Result)
                     find_aptc.failure.errors.to_h
                   else
                     find_aptc.failure
                   end

          @logger.error "Failed FindAptc: #{errors}, for enrollment with hbx_id: #{enrollment.hbx_id}"
          next enrollment
        end

        enrollment.update_tax_household_enrollment
      end

      benchmark_product_request_payload, benchmark_product_response_payload = if thh_enrs_newly_created
        benchmark_product = ::BenchmarkProduct.where(family_id: family.id).order(created_at: :desc).first
        [benchmark_product.request, benchmark_product.response]
      else
        ['N/A', 'N/A']
      end

      enrollment_members_info = enrollment.hbx_enrollment_members.inject({}) do |member_hash, member|
        member_hash[member.person.full_name] = [member.coverage_start_on, member.person.hbx_id]
        member_hash
      end

      TaxHouseholdEnrollment.where(enrollment_id: enrollment.id).each do |thh_enr|
        thh_enr.reload.tax_household_members_enrollment_members.each do |member|
          csv << [
            family.primary_person.hbx_id,
            enrollment.hbx_id,
            enrollment.effective_on,
            enrollment.aasm_state,
            enrollment_members_info,
            thh_enrs_newly_created,
            thh_enr.household_benchmark_ehb_premium,
            thh_enr.health_product_hios_id,
            thh_enr.dental_product_hios_id,
            thh_enr.household_health_benchmark_ehb_premium,
            thh_enr.household_dental_benchmark_ehb_premium,
            thh_enr.applied_aptc,
            thh_enr.available_max_aptc,
            thh_enr.group_ehb_premium,
            member.age_on_effective_date,
            member.relationship_with_primary,
            member.date_of_birth,
            benchmark_product_request_payload,
            benchmark_product_response_payload
          ]
        end
      end

      @logger.info "Processed #{counter.ordinalize} eligible enrollments" if counter % 10 == 0
    rescue StandardError => e
      @logger.error "Failed to process enrollment with hbx_id: #{enrollment.hbx_id}, message: #{e}, backtrace: #{e.backtrace}"
    end
  end
end
# rubocop:enable Metrics/AbcSize, Metrics/MethodLength

start_time = DateTime.current
@logger = Logger.new("#{Rails.root}/handle_missing_thh_enrs_for_aptc_enrs_#{Date.today.strftime('%Y_%m_%d_%H_%M')}.log")
@logger.info "Process start_time: #{start_time}"
@processing_year = 2022

enrollments = HbxEnrollment.by_year(@processing_year).where(
  coverage_kind: 'health',
  :aasm_state.nin => ['coverage_canceled', 'shopping'],
  :"applied_aptc_amount.cents".gt => 0,
  :_id.nin => TaxHouseholdEnrollment.all.distinct(:enrollment_id)
)

file_name = "#{Rails.root}/handle_missing_thh_enrs_for_aptc_enrs_report_#{Time.now.strftime('%Y_%m_%d_%H_%M')}.csv"

field_names = [
  'Primary Member HBX ID',
  'Enrollment HBX ID',
  'Enrollment Effective Date',
  'Enrollment State',
  'Enrollment Members Information',
  'TaxHouseholdEnrollments newly created?',
  'thh_enr_household_benchmark_ehb_premium',
  'thh_enr_health_product_hios_id',
  'thh_enr_dental_product_hios_id',
  'thh_enr_household_health_benchmark_ehb_premium',
  'thh_enr_household_dental_benchmark_ehb_premium',
  'thh_enr_applied_aptc',
  'thh_enr_available_max_aptc',
  'thh_enr_group_ehb_premium',
  'thh_enr_member_age_on_effective_date',
  'thh_enr_member_relationship_with_primary',
  'thh_enr_member_date_of_birth',
  'benchmark_product_request_payload',
  'benchmark_product_response_payload'
]
process_enrollments(enrollments, field_names, file_name)
end_time = DateTime.current
@logger.info "Process end_time: #{end_time}, total_time_taken_in_minutes: #{((end_time - start_time) * 24 * 60).to_i}"
