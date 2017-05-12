require File.join(Rails.root, "lib/mongoid_migration_task")
class DelinkBroker < MongoidMigrationTask
  def migrate
    person=Person.where(first_name:"Carolyn",last_name:"Robbins").first
    if person.broker_role
      organization = FactoryGirl.create(:broker_agency_profile)
      bpa_id = organization.id
      person.broker_role.update_attributes(broker_agency_profile_id: bpa_id)
      person.broker_role.save
    else
      puts "Error for Person id: #{person.first_name}"

    end
  end
end
