namespace :migrations do

  desc "Create employee roles"
  task :create_employee_roles => :environment do
    counter = 1

    Family.where(:"households.hbx_enrollments.kind" => 'employer_sponsored').each do |family|
      if counter % 100 == 0
        puts "processed #{counter}"
      end

      counter += 1
      begin
        employee = family.primary_applicant.person
      rescue
        next
      end

      hbx_enrollments = family.active_household.hbx_enrollments.where(:kind => 'employer_sponsored').where(:aasm_state.ne => 'shopping').to_a
      hbx_enrollments.reject!{|e| e.benefit_group_assignment.blank?}
      hbx_enrollments.group_by{|e| e.benefit_group_assignment.census_employee }.each do |census_employee, enrollments|

        if employee.employee_roles.where(:census_employee_id => census_employee.id).blank?
          employee_role = employee.employee_roles.build({
            employer_profile: census_employee.employer_profile, 
            hired_on: census_employee.hired_on,
            census_employee: census_employee,
            terminated_on: census_employee.employment_terminated_on})

          if employee_role.save
            census_employee.update_attributes(:employee_role_id => employee_role.id)
            enrollments.each{|e| e.update_attributes(:employee_role_id => employee_role.id) }

            puts "Created employee role for #{census_employee.full_name}"
          else
            puts "Failed to save employee role for #{census_employee.full_name}"
          end
        end
      end
    end
  end
end