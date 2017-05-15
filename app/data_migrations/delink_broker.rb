require File.join(Rails.root, "lib/mongoid_migration_task")
class DelinkBroker < MongoidMigrationTask
  def migrate
    first_name = ENV['first_name']
    last_name = ENV['last_name']
    legal_name = ENV['legal_name']
    person=Person.where(first_name: first_name,last_name: last_name).first
    if person.broker_role
      broker_agency = FactoryGirl.create(:broker_agency_profile,:organization => {:legal_name => legal_name, :fein => "99999322"})
      #update fields
      person.broker_role.update_attributes(broker_agency_profile_id: broker_agency.id)
      person.broker_role.save
    else
      puts "Error for Person id: #{person.first_name}"
    end
  end
end
