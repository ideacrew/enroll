require 'csv'

namespace :reports do
  namespace :shop do

    desc "List of census employee's initiated coverage wavied or coverage terminated of their plan's"
    task :employee_initiated_terminations => :environment do

      date_range = Date.new(2015,10,1)..TimeKeeper.date_of_record

      employees = CensusEmployee.active.any_in("benefit_group_assignments.aasm_state": ['coverage_waived','coverage_terminated']).
                  collect { |employee| employee if (employee.active_benefit_group_assignment ||
                  employee.renewal_benefit_group_assignment) }.compact

      field_names  = %w(
          Employer_Legal_Name
          EE_First_Name
          EE_Last_Name
          SSN
          DOB
          DOH
          DOT_Active_Plan
          Date_Termination_Submitted_Active_Plan
          DOT_Renewal_Plan
          Date_Termination_Submitted_Renewal_Plan
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
              employee.active_benefit_group_assignment.try(:plan_year).try(:end_on),
              employee.active_benefit_group_assignment.try(:updated_at),
              employee.renewal_benefit_group_assignment.try(:plan_year).try(:end_on),
              employee.renewal_benefit_group_assignment.try(:updated_at)
          ]
          processed_count += 1
        end
      end

      puts "For period #{date_range.first} - #{date_range.last}, #{processed_count} employees to output file: #{file_name}"
    end
  end
end

