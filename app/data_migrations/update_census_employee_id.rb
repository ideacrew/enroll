require File.join(Rails.root, "lib/mongoid_migration_task")
class UpdateCensusEmployeeId< MongoidMigrationTask
  def migrate
      id = ENV["employee_role_id"].to_s
      input_id = ENV['census_employee_id']
      employee_role = EmployeeRole.find(id)
       
      if employee_role.nil?
        puts "Employee Role nil" unless Rails.env.test?
      end
      
      employee_role.update_attributes(census_employee_id: input_id)
      puts 'Updated census empoyee id' unless Rails.env.test? 
  end
end