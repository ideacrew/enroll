# frozen_string_literal: true

# This script generates a CSV report with information about Enrollments with TaxHouseholdEnrollments
# To run this for all enrollments effectuated on or after 2022/1/1
# bundle exec rails runner script/list_of_tax_household_enrollments.rb

# To run this on specific enrollments
# bundle exec rails runner script/list_of_tax_household_enrollments.rb enr_hbx_ids='127633, 1987222, 3746543'

def process_enrollments(enrollments, logger)
  file_name = "#{Rails.root}/list_of_enrollments_with_thh_enr_info.csv"
  field_names = %w[person_hbx_id
                   enrollment_hbx_id
                   enrollment_effective_on
                   enrollment_terminated_on
                   enrollment_aasm_state
                   enrollment_total_premium
                   product_ehb
                   enrollment_applied_aptc_amount
                   thh_applied_aptc
                   thh_available_max_aptc
                   thh_enr_group_ehb_premium
                   tax_household_members
                   household_benchmark_ehb_premium
                   health_product_hios_id
                   dental_product_hios_id
                   household_health_benchmark_ehb_premium
                   household_dental_benchmark_ehb_premium]

  CSV.open(file_name, 'w', force_quotes: true) do |csv|
    csv << field_names
    enrollments.no_timeout.each do |enrollment|
      person = enrollment.family.primary_person
      thh_enrs = TaxHouseholdEnrollment.where(enrollment_id: enrollment.id)
      logger.info "No TaxHouseholdEnrollment objects for given enrollment with hbx_id: #{enrollment.hbx_id}, PrimaryPersonHbxId: #{person.hbx_id}" if thh_enrs.blank?

      thh_enrs.each do |thh_enr|
        thh = thh_enr.tax_household
        valid_thh_members = thh.tax_household_members.where(:id.in => thh_enr.tax_household_members_enrollment_members.pluck(:tax_household_member_id))

        csv << [
          person.hbx_id,
          enrollment.hbx_id,
          enrollment.effective_on,
          enrollment.terminated_on,
          enrollment.aasm_state,
          enrollment.total_premium.to_f,
          enrollment.product.ehb,
          enrollment.applied_aptc_amount.to_f,
          thh_enr.applied_aptc,
          thh_enr.available_max_aptc,
          thh_enr.group_ehb_premium,
          valid_thh_members.map(&:person).flat_map(&:full_name),
          thh_enr.household_benchmark_ehb_premium,
          thh_enr.health_product_hios_id,
          thh_enr.dental_product_hios_id,
          thh_enr.household_health_benchmark_ehb_premium,
          thh_enr.household_dental_benchmark_ehb_premium
        ]
      end
    rescue StandardError => e
      logger.info "Error raised for EnrHbxID: #{enrollment.hbx_id}, message: #{e}"
    end
  end
end

def find_enrollments
  show_enrollments_sans_canceled = %w[coverage_selected transmitted_to_carrier coverage_enrolled coverage_termination_pending unverified coverage_reinstated auto_renewing renewing_coverage_selected renewing_transmitted_to_carrier
                                      renewing_coverage_enrolled auto_renewing_contingent renewing_contingent_selected renewing_contingent_transmitted_to_carrier renewing_contingent_enrolled coverage_terminated coverage_expired
                                      inactive renewing_waived]

  hbx_ids = ENV['enr_hbx_ids'].to_s.split(',').map(&:squish!)

  if hbx_ids.present?
    HbxEnrollment.by_coverage_kind('health').where(:effective_on.gte => Date.new(2022), :aasm_state.in => show_enrollments_sans_canceled, :hbx_id.in => hbx_ids)
  else
    HbxEnrollment.by_coverage_kind('health').where(:effective_on.gte => Date.new(2022), :aasm_state.in => show_enrollments_sans_canceled)
  end
end

start_time = DateTime.current
logger = Logger.new("#{Rails.root}/enrollments_with_thh_enr_info_log_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
logger.info "TaxHousehold Enrollment Report start_time: #{start_time}"
enrollments = find_enrollments
process_enrollments(enrollments, logger)
end_time = DateTime.current
logger.info "TaxHousehold Enrollment Report end_time: #{end_time}, total_time_taken_in_minutes: #{((end_time - start_time) * 24 * 60).to_i}"
