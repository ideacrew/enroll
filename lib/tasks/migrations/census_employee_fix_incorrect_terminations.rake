namespace :migrations do

  desc "fix roster records"
  task :census_employee_fix_incorrect_terminations, [:first_name, :last_name, :dob] => :environment do |task, args|
    
    census_employees = CensusEmployee.where(:first_name => /#{args[:first_name]}/i, :last_name => /#{args[:last_name]}/i, :dob => args[:dob] )
    census_employees_with_enrollments = census_employees.select{|ce| ce.active_benefit_group_assignment.present? && ce.active_benefit_group_assignment.hbx_enrollments.present?}
    
    if census_employees_with_enrollments.size == 1
      census_employee = census_employees_with_enrollments.first
      puts "Processing #{census_employee.full_name}"
      puts "Identified correct roster record"

      census_employee.employment_terminated_on = nil
      census_employee.coverage_terminated_on = nil
      census_employee.aasm_state = census_employee.employee_role_id.present? ? 'employee_role_linked' : 'eligible'
      census_employee.save(:validate => false)
      puts "Enabled correct roster record"

      census_employees.reject{|ce| ce == census_employee}.each do |ce|
        unless ce.employment_terminated?
          ce.employment_terminated_on = TimeKeeper.date_of_record
          ce.aasm_state = 'employment_terminated'
          ce.save(:validate => false)
          puts "Terminated invalid roster record with current date"
        end
      end
    end
  end
end