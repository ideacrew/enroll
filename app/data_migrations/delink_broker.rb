require File.join(Rails.root, "lib/mongoid_migration_task")
class DelinkBroker < MongoidMigrationTask
  def migrate
    hbx_id = ENV['person_hbx_id']
    legal_name = ENV['legal_name']
    fein = ENV['fein']
    person=Person.where(hbx_id: hbx_id).first
    if person.broker_role
      broker_agency = FactoryGirl.create(:broker_agency_profile,:organization => {:legal_name => legal_name, :fein => fein})
      #update fields
      person.broker_role.update_attributes(broker_agency_profile_id: broker_agency.id)
      person.broker_role.save
    else
      puts "Error for Person: #{person.first_name}" unless Rails.env.test?
    end
  end
end
