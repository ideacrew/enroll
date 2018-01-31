require 'csv'

namespace :reports do
  namespace :shop do

    desc "Employee-initiated terminations by employer profile and date range"
    task :employee_terms_employee_initiated => :environment do

      start_date = Date.new(2015,10,1)
      end_date = TimeKeeper.date_of_record
      date_range = start_date..end_date

      families = Family.
                  by_enrollment_shop_market.
                  any_in(:"households.hbx_enrollments.aasm_state" => HbxEnrollment::TERMINATED_STATUSES).
                  by_enrollment_updated_datetime_range(start_date, end_date)

      census_employees = families.inject([]) do |employees, family|
        terminated_enrollments = family.latest_household.hbx_enrollments.any_in(aasm_state: HbxEnrollment::TERMINATED_STATUSES).
                where(:"updated_at" => { "$gte" => start_date, "$lte" => end_date} )
        employees += terminated_enrollments.map(&:benefit_group_assignment).compact.map(&:census_employee).uniq
      end


      # enrollments = families.reduce([]) do |list, family|
      #   list << family.latest_household.hbx_enrollments.any_in(aasm_state: HbxEnrollment::TERMINATED_STATUSES).
      #             by_enrollment_updated_datetime_range(start_date, end_date)
      # end

      field_names  = %w(
          employer_name last_name first_name ssn dob aasm_state hired_on employment_terminated_on updated_at 
        )

      processed_count = 0
      file_name = "#{Rails.root}/public/employee_terms_employee_initiated.csv"

      CSV.open(file_name, "w", force_quotes: true) do |csv|
        csv << field_names

        census_employees.each do |census_employee|
          last_name                 = census_employee.last_name
          first_name                = census_employee.first_name
          ssn                       = census_employee.ssn
          dob                       = census_employee.dob
          hired_on                  = census_employee.hired_on
          employment_terminated_on  = census_employee.employment_terminated_on
          aasm_state                = census_employee.aasm_state
          updated_at                = census_employee.updated_at.localtime

          employer_name = census_employee.employer_profile.organization.legal_name

          # Only include ERs active on the HBX 
          active_states = %w(registered eligible binder_paid enrolled suspended)

          if active_states.include? census_employee.employer_profile.aasm_state
            csv << field_names.map do |field_name| 
              if field_name == "ssn"
                '="' + eval(field_name) + '"'
              else
                eval("#{field_name}")
              end
            end
            processed_count += 1
          end
        end
      end

      puts "For period #{date_range.first} - #{date_range.last}, #{processed_count} employee terminations output to file: #{file_name}"
    end
  end
end