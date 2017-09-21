require File.join(Rails.root, "lib/mongoid_migration_task")

class PopulateEmployeeRoleIdOnCensusEmployees < MongoidMigrationTask
  def migrate
  	organizations = Organization.where(fein: ENV['fein'])
		if organizations.size != 1
		  puts "please provide more reliable input"
		  return
		end

		employer_profile = organizations.first.employer_profile
		employer_profile.census_employees.terminated.where(employee_role_id: nil).each do |census_employee|
		  begin
		    people = Person.where(encrypted_ssn: census_employee.encrypted_ssn)
		    if people.size != 1
		      puts "check census_employee: #{census_employee.full_name}" if people.size > 1
		      next
		    end

		    employee_roles = people.first.employee_roles.where(employer_profile_id: employer_profile.id)
		    if employee_roles.size > 1
		      if employee_roles.detect { |er| er.census_employee.aasm_state == "rehired"}.present?
		        puts "rehired!!" unless Rails.env.test?
		      else
		        puts "check census_employee: #{census_employee.full_name}" unless Rails.env.test?
		      end
		      next
		    end

		    census_employee.update_attributes!(employee_role_id: employee_roles.first.id)

		    puts "succesfullly updated employee role on census_employee: #{census_employee.full_name}" unless Rails.env.test?
		  rescue Exception => e
		    puts "#{e}"
		  end
		end
  end
end
