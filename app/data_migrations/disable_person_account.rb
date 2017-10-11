require File.join(Rails.root, "lib/mongoid_migration_task")
class DisablePersonAccount< MongoidMigrationTask
  def migrate
    hbx_id = ENV['hbx_id']
    person = Person.where(hbx_id:hbx_id).first
    if person.nil?
      puts "No person was found by the given hbx_id" unless Rails.env.test?
      return
    end
    person.update_attributes!(is_active: false)
    puts "Disable person with hbx_id #{hbx_id}" unless Rails.env.test?
  end
end
