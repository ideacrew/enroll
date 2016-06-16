require 'csv'

namespace :reports do
  namespace :shop do

    desc "List of census employee's initiated termination of benefit group assignment"
    task :employee_initiated_terminations => :environment do

      date_range = Date.new(2015,10,1)..TimeKeeper.date_of_record
      employees=CensusEmployee.active.any_in("benefit_group_assignments.is_active": true,"benefit_group_assignments.aasm_state": ['coverage_waived','coverage_terminated'])

      field_names  = %w(
          Employer_Legal_Name
          EE_First_Name
          EE_Last_Name
          SSN
          DOB
          DOH
          DOT
          Date_Termination_Submitted
        )
      processed_count = 0
      file_name = "#{Rails.root}/public/employee_initiated_termination.csv"

      CSV.open(file_name, "w", force_quotes: true) do |csv|
        csv << field_names

        employees.each do |employee|
          csv << [
              employee.employer_profile.legal_name,
              employee.first_name,
              employee.last_name,
              employee.ssn,
              employee.dob,
              employee.hired_on,
              employee.active_benefit_group_assignment.benefit_group.plan_year.end_on,
              employee.active_benefit_group_assignment.updated_at
          ]
          processed_count += 1
        end
      end

      puts "For period #{date_range.first} - #{date_range.last}, #{processed_count} employees to output file: #{file_name}"
    end
  end
end