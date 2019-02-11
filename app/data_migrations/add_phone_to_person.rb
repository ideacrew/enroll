require File.join(Rails.root, "lib/mongoid_migration_task")
class AddPhoneToPerson < MongoidMigrationTask
  def migrate
    begin
      hbx_id = ENV['hbx_id']
      person=Person.where(hbx_id:hbx_id).first
      full_phone_number = ENV['full_phone_number']
      kind = ENV['kind']

      if person.nil?
        puts "No person was found by the given hbx_id" unless Rails.env.test?
      else
        person.phones << Phone.new(full_phone_number: full_phone_number, kind: kind)
        person.save!
        puts "Adding phone to person #{hbx_id}" unless Rails.env.test?
      end
    rescue => e
      puts "#{e}"
    end
  end
end
