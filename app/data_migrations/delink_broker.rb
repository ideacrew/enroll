require File.join Rails.root, "lib/mongoid_migration_task"

class DelinkBroker < MongoidMigrationTask
  def migrate
    hbx_id = ENV['person_hbx_id']
    legal_name = ENV['legal_name']
    organization_ids_to_move = ENV['organization_ids_to_move']
    fein = ENV['fein']
    person=Person.where(hbx_id: hbx_id).first
    if person.broker_role
      # broker_agency = FactoryGirl.create(:broker_agency_profile,:organization => {:legal_name => legal_name, :fein => fein})
      hbx_office = OfficeLocation.new(
      is_primary: true, 
      address: {kind: "work", address_1: "address_placeholder", address_2: "609 H St, Room 415", city: "Washington", state: "DC", zip: "20002" }, 
      phone: {kind: "main", area_code: "202", number: "555-1212"}
      )

      org = Organization.create(office_locations: [hbx_office], fein: fein, legal_name: legal_name)
      broker_agency_profile = BrokerAgencyProfile.create(market_kind: "both",
                                                      entity_kind: "s_corporation",
                                                      organization: org)
      #update fields
      person.broker_role.update_attributes(broker_agency_profile_id: broker_agency_profile.id)
      person.broker_role.save
      #move organizations under to newly created borker agency profile 
      if organization_ids_to_move.present?
      organization_ids_to_move.each do |organization_id|
      org = Organization.find(organization_id)
      old_broker_agency = org.employer_profile.broker_agency_accounts.where(:is_active => true).first
      unless old_broker_agency.nil?
        old_broker_agency.update_attributes!(:is_active => false)
        broker_agency_account = BrokerAgencyAccount.new(broker_agency_profile_id: org.broker_agency_profile.id, writing_agent_id: person.broker_role.id, start_on: TimeKeeper.datetime_of_record, is_active: true)
        org.employer_profile.broker_agency_accounts.push(broker_agency_account)
    end
  end
    else
      puts "Error for Person: #{person.first_name}" unless Rails.env.test?
    end
  end
end