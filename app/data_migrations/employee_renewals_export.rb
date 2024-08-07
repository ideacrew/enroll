# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

# census employees current and renewal coverage details csv export
class EmployeeRenewalsExport < MongoidMigrationTask

  def migrate
    start_on_date = Date.strptime(ENV['start_on_date'].to_s, "%m/%d/%Y")
    puts 'Creating detail report...'
    detailed_report(start_on_date)
  end

  def benefit_applications_in_aasm_state(aasm_states, start_on_date)
    BenefitSponsors::BenefitSponsorships::BenefitSponsorship.where(
      "benefit_applications.effective_period.min = ? AND
  benefit_applications.predecessor_id IS NOT NULL AND
  benefit_applications.aasm_state IN (?)",
      start_on_date,
      aasm_states
    )
  end

  def detailed_report_field_names(start_on_date)
    [
      "Employer Legal Name",
      "Employer FEIN",
      "Employer HBX ID",
      "#{start_on_date.prev_year.year} effective_date",
      "#{start_on_date.prev_year.year} State",
      "#{start_on_date.year} effective_date",
      "#{start_on_date.year} State",
      "First name",
      "Last Name",
      "Roster status",
      "Hbx ID",
      "#{start_on_date.prev_year.year} enrollment",
      "#{start_on_date.prev_year.year} enrollment kind",
      "#{start_on_date.prev_year.year} plan",
      "#{start_on_date.prev_year.year} effective_date",
      "#{start_on_date.prev_year.year} status",
      "#{start_on_date.year} enrollment",
      "#{start_on_date.year} enrollment kind",
      "#{start_on_date.year} plan",
      "#{start_on_date.year} effective_date",
      "#{start_on_date.year} status",
      "Reasons"
    ]
  end

  def census_employee_family(census_employee)
    family = census_employee.family
    return family if family

    if Person.by_ssn(census_employee.ssn).present? && Person.by_ssn(census_employee.ssn).employee_roles.select{|e| e.census_employee_id == census_employee.id && e.is_active == true}.present?
      person = Person.by_ssn(census_employee.ssn).first
      family = person.primary_family
    end

    family
  end

  def current_enrollments(family, application)
    family.active_household.hbx_enrollments.where(
      :sponsored_benefit_package_id.in => application.benefit_packages.pluck(:id),
      :aasm_state.nin => ["shopping", "coverage_canceled"]
    )
  end

  def predecessor_enrollments(family, predecessor)
    family.active_household.hbx_enrollments.where(
      :sponsored_benefit_package_id.in => predecessor.benefit_packages.pluck(:id),
      :aasm_state.nin => ["shopping", "coverage_canceled"]
    )
  end

  def enrollment_fields_for(enrollment = nil)
    return 5.times.collect{ nil } unless enrollment
    [
      enrollment.hbx_id,
      enrollment.coverage_kind,
      enrollment.product&.hios_id,
      enrollment.effective_on,
      enrollment.aasm_state
    ]
  end

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def detailed_report(start_on_date)
    file_name = "#{Rails.root}/employee_renewals_export_report_#{start_on_date.strftime('%Y_%m_%d')}.csv"

    valid_statuses = [
      :active, :termination_pending, :terminated, :expired, :enrollment_open, :enrollment_extended,
      :enrollment_closed, :enrollment_eligible, :binder_paid, :enrollment_ineligible
    ]
    sponsorships = benefit_applications_in_aasm_state(valid_statuses, start_on_date)

    CSV.open(file_name, "w", force_quotes: true) do |csv|
      csv << detailed_report_field_names(start_on_date)
      sponsorships.no_timeout.each do |ben_spon|
        p "processing....#{ben_spon.legal_name}"
        application = ben_spon.benefit_applications.where({
                                                            :"effective_period.min" => start_on_date,
                                                            :predecessor_id => {"$ne" => nil},
                                                            :aasm_state.in => valid_statuses
                                                          }).first

        predecessor = application.predecessor
        ben_spon.census_employees.active.each do |census_employee|
          family = census_employee_family(census_employee)
          next unless family

          current_enrollments = current_enrollments(family, application)
          predecessor_enrollments = predecessor_enrollments(family, predecessor)

          ["health", "dental"].each do |kind|
            enrollment_prev_year = predecessor_enrollments.by_coverage_kind(kind).last
            enrollment_current_year = current_enrollments.by_coverage_kind(kind).last

            data = [
                      ben_spon.profile.legal_name,
                      ben_spon.profile.fein,
                      ben_spon.profile.hbx_id,
                      predecessor.effective_period.min,
                      predecessor.aasm_state,
                      application.effective_period.min,
                      application.aasm_state,
                      census_employee.first_name,
                      census_employee.last_name,
                      census_employee.aasm_state,
                      family.primary_applicant.person.hbx_id
                    ]
            data += enrollment_fields_for(enrollment_prev_year)
            data += enrollment_fields_for(enrollment_current_year)
            data += [
              find_failure_reason(
                enrollment_prev_year: enrollment_prev_year,
                enrollment_current_year: enrollment_current_year,
                application: application
              )
            ]
            csv << data
          end
        end
      end
    end
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def find_failure_reason(enrollment_prev_year:, enrollment_current_year:, application:)
    current_year_state = enrollment_current_year&.aasm_state
    prev_year_state = enrollment_prev_year&.aasm_state
    rp_id = enrollment_prev_year&.product&.renewal_product_id
    cp_id = enrollment_current_year&.product&.id

    if current_year_state == 'auto_renewing'
      "Successfully Generated"
    elsif current_year_state == 'coverage_enrolled'
      "The plan year was manually published by stakeholders" if ["active","enrollment_eligible"].include?(application.aasm_state)
    elsif current_year_state == "coverage_selected"
      "Plan was manually selected for the current year" unless rp_id == cp_id
    elsif ["inactive","renewing_waived"].include?(current_year_state)
      "enrollment is waived"
    elsif current_year_state.nil? && application.aasm_state == 'pending'
      "ER zip code is not in DC"
    elsif current_year_state.nil? && prev_year_state.in?(HbxEnrollment::WAIVED_STATUSES + HbxEnrollment::TERMINATED_STATUSES)
      "Previous plan has waived or terminated and did not generate renewal"
    elsif current_year_state.nil? && ["coverage_selected", "coverage_enrolled"].include?(prev_year_state)
      "Enrollment plan was changed either for current year or previous year" unless rp_id == cp_id
    else
      ''
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
end
