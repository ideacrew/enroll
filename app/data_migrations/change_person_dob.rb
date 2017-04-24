require File.join(Rails.root, "lib/mongoid_migration_task")
class ChangePersonDob< MongoidMigrationTask
  def migrate
    person=Person.where(hbx_id:ENV['hbx_id']).first
    new_dob = ENV['new_dob']
    if person.nil?
      puts "No person was found by the given fein"
    else
      person.update_attributes(dob:new_dob)
      puts "Changed date of birth to #{new_dob}" unless Rails.env.test?
    end
  end
end
