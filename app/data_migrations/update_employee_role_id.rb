require File.join(Rails.root,"lib/mongoid_migration_task")
class UpdateEmployeeRoleId < MongoidMigrationTask
  def migrate
    person_hbx_id = ENV['hbx_id']
    
    person = Person.where(hbx_id: person_hbx_id).first

    if person.present? && person.has_active_employee_role?
      
      active_employee_role_id = person.active_employee_roles.first.id

      person.primary_family.active_household.hbx_enrollments.each do |enr|
        
        if (enr.employee_role_id == active_employee_role_id)
          puts "Enrollment #{enr.hbx_id} is pointing towards the right Employee"  unless Rails.env.test?
        else
          enr.update_attributes!(employee_role_id: active_employee_role_id)
           puts "Fixed Enrollment #{enr.hbx_id} by pointing the Enrollment towards the right Employee of hbx id #{person_hbx_id}"  unless Rails.env.test?
        end
      end
      else
       puts "Please check the hbx id the id given is not present or has no active employee roles"  unless Rails.env.test?
    end
  end
end
