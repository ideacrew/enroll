
require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateBrokerPhoneKind < MongoidMigrationTask
  def migrate
    organizations = Organization.where(fein: ENV['fein'])
    if organizations.size !=1
      raise 'Issues with fein'
    end
    
    organizations.first.broker_agency_profile.active_broker_roles.first.parent.phones.first.update(:kind => "work")
  end
end