
require File.join(Rails.root, "lib/mongoid_migration_task")

class ChangeHbxId< MongoidMigrationTask
  def migrate
    begin
      hbx_id = ENV['person_hbx_id']
      new_hbx_id = ENV['new_hbx_id']
      person = Person.where(hbx_id: hbx_id).first
      new_person = Person.where(hbx_id: new_hbx_id).first
      if person.nil?
        puts "No person was found by the given hbx_id: #{hbx_id}" unless Rails.env.test?
        return
      end
      unless new_person.nil?
        puts "The new hbx_id: #{hbx_id} has been taken by an existing person in the system" unless Rails.env.test?
        return
      end
      new_hbx_id = HbxIdGenerator.generate_member_id if new_hbx_id.empty?
      person.update_attributes(hbx_id: new_hbx_id)
      puts "change hbx_id from #{hbx_id} to a #{new_hbx_id} " unless Rails.env.test?
    rescue => e
      puts "#{e}"
    end
  end
end