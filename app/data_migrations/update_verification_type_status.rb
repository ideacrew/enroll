require File.join(Rails.root, "lib/mongoid_migration_task")
class UpdateVerificationTypeStatus < MongoidMigrationTask
  def migrate
    begin
      census_employee = Person.where(id: ENV['hbx_id']).first
      if census_employee.nil?
        puts "No person record found for given HBX ID" unless Rails.env.test?
      else
        verification_type = person.verification_types.where(type_name: ENV['verification_type_name'] )
        verification_type.pass_type if verification_type && verification_type.type_name == 'pending'
        puts "Changed verification type validation status" unless Rails.env.test?
      end
    rescue StandardError => e
      puts e.message
    end
  end
end
