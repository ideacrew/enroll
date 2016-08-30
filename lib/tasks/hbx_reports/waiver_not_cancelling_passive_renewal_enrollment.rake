require 'csv'

namespace :reports do
  namespace :shop do

    desc "List of EEs in with waived coverage state on ER roster, but has an active 7/1 renewal policy in EE account"
    task :waiver_not_cancelling_passive_renewals => :environment do
      count = 0
      renewal_policy_date = Date.new(2016,7,1)
      # All Renewing Employers - Includes Conversion Employers too.
      all_renewing_employers = Organization.where(:"employer_profile.plan_years" => {:$elemMatch => {:start_on => renewal_policy_date, :aasm_state.in => PlanYear::RENEWING_PUBLISHED_STATE}})

      file_name = "#{Rails.root}/public/waiver_not_cancelling_passive_renewals.csv"
      field_names  = %w(Employer_Name Employee_First_Name Employee_Last_Name SSN DOB)

      CSV.open(file_name, "w") do |csv|
        csv << field_names

        all_renewing_employers.each do |employer|
          census_employees = employer.employer_profile.census_employees
          
          census_employees.each do |ce|
            renewing_enrollments = ce.try(:renewal_benefit_group_assignment).try(:hbx_enrollments)
            next if renewing_enrollments.blank?
            renewing_enrollment_statuses = renewing_enrollments.map(&:aasm_state)

            # If there are renewing enrollments with both [ Waived(inactive) and Renewing ] statuses for an employee, we want to report them.
            if (renewing_enrollment_statuses &  HbxEnrollment::RENEWAL_STATUSES).present? && (renewing_enrollment_statuses &  HbxEnrollment::WAIVED_STATUSES).present?
              count += 1
              csv << [
                ce.employer_profile.organization.legal_name,
                ce.first_name,
                ce.last_name,
                ce.ssn,
                ce.dob
              ]
            end
          end

        end

      end # CSV close
    end

  end
end