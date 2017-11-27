require File.join(Rails.root, "lib/mongoid_migration_task")

class DelinkEmployeeRole < MongoidMigrationTask
  def migrate
    person_hbx_id = ENV['correct_person_hbx_id']
    person = Person.where(hbx_id:person_hbx_id).first
        if person.nil?
        puts "No person was found with given hbx_id" unless Rails.env.test?
        else
          person.employee_roles.first.unset(:census_employee_id)
        end
  end
end

