require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateBrokerAgencyProfileId < MongoidMigrationTask

  def migrate
    user = User.where(email: ENV['email']).first
    if user.blank?
      puts 'Issues with email'
      return
    end
     person = user.person
     person.broker_agency_staff_roles.first.update_attributes(broker_agency_profile_id: person.broker_role.broker_agency_profile_id)
     puts "Updating broker agency profile id for User with email: #{ENV['email']} " unless Rails.env.test?
   end
end