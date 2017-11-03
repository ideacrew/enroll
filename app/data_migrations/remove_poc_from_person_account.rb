require File.join(Rails.root, "lib/mongoid_migration_task")

class RemovePocFromPersonAccount< MongoidMigrationTask
  def migrate
    hbx_id = ENV['person_hbx_id']
    person = Person.where(hbx_id:hbx_id).first
    if person.nil?
      puts "No person was found by the given hbx_id: #{hbx_id}" unless Rails.env.test?
    else
      person.employer_staff_roles.each do |er_role|
        er_role.delete
      end
      puts "Remove ssn from person with hbx_id  #{hbx_id}" unless Rails.env.test?
    end
  end
end