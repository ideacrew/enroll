require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateBrokerAgencyProfile < MongoidMigrationTask

  def migrate

    user = User.where(email: ENV['email']).first
    if user.blank?
      puts 'Issues with email'
      return
    end
     person = user.person
     person.broker_agency_staff_roles.first.update_attributes(broker_agency_profile: person.broker_role.broker_agency_profile)
   end

end