require File.join(Rails.root, "lib/mongoid_migration_task")

class TerminateEmployeeRole < MongoidMigrationTask
	def migrate
		person = Person.where(hbx_id: ENV['hbx_id']).first
    employee = person.employee_roles.where(_id: ENV['emp_id']).first.census_employee
		if person.blank?
      puts "No person was found with HBX ID provided" unless Rails.env.test?
      return
    elsif employee.blank?
      puts "No employee was found with information provided" unless Rails.env.test?
    else
      employee.terminate_employee_role!
      puts "Employee was successfully terminated." unless Rails.env.test?
    end
	end
end