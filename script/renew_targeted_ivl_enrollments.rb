# frozen_string_literal: true
# This script will attempt to call RenewEnrollment on previously failed enrollments
# and output a CSV of all enrollments still failing.

require 'csv'
year = 2023
read_filename = "#{Rails.root}/pids/#{year}_ivl_enrollments_eligible_renewal_failures.csv"
write_filename = "#{Rails.root}/pids/#{year}_ivl_enrollments_retriggered_renewal_failures.csv"

current_bs = HbxProfile.current_hbx.benefit_sponsorship
renewal_bcp = current_bs.renewal_benefit_coverage_period

CSV.open(write_filename, "wb") do |csv|
  csv << ["enrollment_hbx_id", "primary_hbx_id"]

  CSV.foreach(read_filename) do |row|
    enrollment_hbx_id, primary_hbx_id = row
    current_year_enrollment = HbxEnrollment.by_hbx_id(enrollment_hbx_id).first
    next row if current_year_enrollment.blank?

    result = ::Operations::Individual::RenewEnrollment.new.call(hbx_enrollment: current_year_enrollment, effective_on: renewal_bcp.start_on)
    if result.success?
      renewal_enrollment = result.success
      puts "Successfully able to create renewal enrollment with HBX_ID #{renewal_enrollment.hbx_id}, effective on #{renewal_enrollment.effective_on}, aasm state #{renewal_enrollment.aasm_state}"
    else
      puts "Unable to create renewal enrollment for HBX_ID #{current_year_enrollment.hbx_id}"
      csv << [enrollment_hbx_id, primary_hbx_id]
    end
  rescue StandardError => e
    puts "ERROR on row: #{row}, Backtrace: #{e.backtrace}"
  end
end
