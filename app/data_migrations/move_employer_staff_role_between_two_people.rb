
require File.join(Rails.root, "lib/mongoid_migration_task")

class RemoveHbxId< MongoidMigrationTask
  def migrate
    begin
      from_hbx_id = ENV['from_hbx_id']
      to_hbx_id = ENV['to_hbx_id']
      from_person = Person.where(hbx_id:from_hbx_id).first
      to_person = Person.where(hbx_id:to_hbx_id).first
      if from_person.nil?
        puts "No person was found by the given hbx_id: #{from_hbx_id}" unless Rails.env.test?
        return
      elsif to_person.nil?
        puts  "No person was found by the given hbx_id: #{to_hbx_id}" unless Rails.env.test?
        return
      end

      if from_person.employer_staff_role.empty?
    rescue => e
      puts "#{e}"
    end
  end
end