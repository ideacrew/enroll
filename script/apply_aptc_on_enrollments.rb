# frozen_string_literal: true

# This script is to apply APTC on to the renewal enrollments for all the
# families that are associated with the person hbx_ids given
# in the below file.
require 'csv'
year = 2021
filename = "#{Rails.root}/pids/#{year}_THHEligibility.csv"

def float_fix(float_number)
  BigDecimal((float_number).to_s).round(8).to_f
end

CSV.foreach(filename) do |row_with_ssn|
  puts "----------- Processing row: #{row_with_ssn} -----------"
  ssn, hbx_id, aptc, csr = row_with_ssn
  person = Person.by_hbx_id(hbx_id).first
  if person.blank?
    puts "Person not found for hbx_id: ##{hbx_id}".
    next row_with_ssn
  end

  family = person.primary_family
  if family.blank?
    puts "PrimaryFamily is not found for Person with hbx_id: #{hbx_id}".
    next row_with_ssn
  end

  renewal_enrollments = family.hbx_enrollments.enrolled_and_renewal.where(:effective_on.gte => Date.new(year, 1, 1), coverage_kind: 'health')
  renewal_enrollments.each do |renewal_enr|
    if renewal_enr.applied_aptc_amount > 0
      puts "Renewal Enrollment with hbx_id: #{renewal_enr.hbx_id} has some aptc applied".
      next renewal_enr
    end
    current_enrollments = family.hbx_enrollments.enrolled_and_renewal.current_year.where(coverage_kind: 'health')
    current_enrollment = current_enrollments.detect {|enr| enr.subscriber.applicant_id == renewal_enr.subscriber.applicant_id }

    tax_household = family.active_household.latest_active_thh_with_year(renewal_enr.effective_on.year)
    if tax_household
      max_aptc = tax_household.current_max_aptc.to_f
      default_percentage = EnrollRegistry[:aca_individual_assistance_benefits].setting(:default_applied_aptc_percentage).item
      applied_percentage = current_enrollment&.elected_aptc_pct > 0 ? current_enrollment.elected_aptc_pct : default_percentage
      applied_aptc = float_fix(max_aptc * applied_percentage)

      attrs = {enrollment_id: renewal_enr.id, elected_aptc_pct: applied_percentage, aptc_applied_total: applied_aptc}
      ::Insured::Forms::SelfTermOrCancelForm.for_aptc_update_post(attrs)
    else
      puts "No TaxHousehold found for family: #{family.id}, person_hbx_id: #{person.hbx_id}"
    end
  end
rescue StandardError => e
  puts "Some issue with the row: #{row_with_ssn}, error: #{e.backtrace}"
end
