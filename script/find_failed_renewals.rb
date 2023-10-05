# frozen_string_literal: true
# Find all eligible enrollments that failed to generate a renewal
# and generate a CSV of enrollment and primary member hbx_ids

require "csv"
year = 2023
filename = "/pids/#{year}_eligible_renewal_failures.csv"

current_bcp = HbxProfile.current_hbx.benefit_sponsorship.current_benefit_coverage_period
current_start_on = current_bcp.start_on.to_date
current_end_on = current_bcp.end_on.to_date

CSV.open(filename, "w") do |csv|
  csv << ["enrollment_hbx_id", "primary_hbx_id"]

  query = {
    :kind.in => ['individual', 'coverall'],
    :aasm_state.in => (HbxEnrollment::ENROLLED_STATUSES - ["coverage_renewed", "coverage_termination_pending"]),
    :coverage_kind.in => HbxEnrollment::COVERAGE_KINDS,
    :effective_on => { "$gte" => current_start_on, "$lt" => current_end_on }
  }

  eligible_for_renewal = HbxEnrollment.where(query).order(:effective_on.desc)
  renewed_enrollment_ids = HbxEnrollment.by_year(year + 1).pluck(:predecessor_enrollment_id)
  "Total eligible enrollments: #{eligible_for_renewal.count}"
  "Total enrollments that got renewed: #{renewed_enrollment_ids.count}"
  enrollments_with_missing_renewal = eligible_for_renewal.where(:id.nin => renewed_enrollment_ids)
  "Total #{year} enrollments with missing renewal: #{enrollments_with_missing_renewal.count}"

  enrollments_with_missing_renewal.each do |enrollment|
    csv << [enrollment.hbx_id, enrollment.primary_hbx_enrollment_member.hbx_id]
  end
end
