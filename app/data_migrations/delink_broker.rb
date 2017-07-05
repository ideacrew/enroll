require File.join Rails.root, "lib/mongoid_migration_task"

class DelinkBroker < MongoidMigrationTask

  def migrate
    hbx_id = ENV['person_hbx_id']
    legal_name = ENV['legal_name']
    organization_ids_to_move = ENV['organization_ids_to_move'].split(",")
    fein = ENV['fein']
    person=Person.where(hbx_id: hbx_id).first
    orgn = Organization.where(:fein => fein).first
    if orgn.nil? && person.broker_role
      hbx_office = OfficeLocation.new(
      is_primary: true, 
      address: {kind: "work", address_1: "21 Church St", address_2: "Suite 100", city: "Rockville", state: "MD", zip: "20850" },
      phone: {kind: "main", area_code: "301", number: "509-3088"}
      )

      org = Organization.create(office_locations: [hbx_office], fein: fein, legal_name: legal_name, is_fake_fein: true)
      broker_agency_profile = BrokerAgencyProfile.create(market_kind: "both",
                                                      entity_kind: "s_corporation",
                                                      primary_broker_role_id: person.broker_role.id,
                                                      default_general_agency_profile_id: BSON::ObjectId('57334ab5082e761cd7000025'),
                                                      organization: org)
      org.save

      #update fields
      person.broker_role.update_attributes(broker_agency_profile_id: broker_agency_profile.id)
      person.broker_role.save
      #move organizations under to newly created borker agency profile 
      if organization_ids_to_move.present?
        organization_ids_to_move.each do |organization_id|
          org_er = Organization.find(organization_id)
          old_broker_agency = org_er.employer_profile.broker_agency_accounts.where(:is_active => true).first
          old_broker_agency.update_attributes!(:is_active => false) unless old_broker_agency.nil?
          broker_agency_account = BrokerAgencyAccount.new(broker_agency_profile_id: org.broker_agency_profile.id, writing_agent_id: person.broker_role.id, start_on: TimeKeeper.datetime_of_record, is_active: true)
          org_er.employer_profile.broker_agency_accounts.push(broker_agency_account)
          org_er.save
        end
      end
    else
      puts "Error for Person: #{person.first_name}" unless Rails.env.test?
    end
  end
end