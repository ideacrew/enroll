require File.join(Rails.root, "lib/mongoid_migration_task")
class UpdateVerificationTypeStatus < MongoidMigrationTask
  def migrate
    begin
      person = Person.where(hbx_id: ENV['hbx_id']).first
      if person.nil?
        puts "No person record found for given HBX ID" unless Rails.env.test?
      else
        verification_type = person.verification_types.where(type_name: ENV['verification_type_name']).first
        verification_type.pass_type if verification_type && verification_type.validation_status == 'pending'
        puts "Changed verification type validation status" unless Rails.env.test?
      end
    rescue StandardError => e
      puts e.message
    end
  end
end
