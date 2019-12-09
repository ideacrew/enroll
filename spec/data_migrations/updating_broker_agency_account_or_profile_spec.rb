require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "updating_broker_agency_account_or_profile")

describe UpdatingBrokerAgencyAccountOrProfile, dbclean: :after_each do

  after(:each) do
    DatabaseCleaner.clean
  end

  let!(:given_task_name) { "delinking_broker" }
  let!(:person) { FactoryBot.create(:person,:with_broker_role)}
  let!(:organization1) {FactoryBot.create(:organization)}
  let!(:organization) {FactoryBot.create(:organization)}
  let!(:fein){"929129912"}
  let!(:employer_profile) { FactoryBot.create(:employer_profile, organization: organization)}
  let!(:broker_agency_profile) {FactoryBot.create(:broker_agency_profile, organization: organization1)}
  let!(:office_locations_contact) {FactoryBot.build(:phone, kind: "work")}
  let!(:office_locations) {FactoryBot.build(:address, kind: "branch")}
  let!(:broker_agency_account) {FactoryBot.create(:broker_agency_account, broker_agency_profile: broker_agency_profile, writing_agent_id: person.broker_role.id, is_active: true, employer_profile: employer_profile)}
  let!(:new_person) { FactoryBot.create(:person)}
  let!(:family) {FactoryBot.create(:family,:with_primary_family_member, person:new_person, broker_agency_accounts:[broker_agency_account])}

  subject { UpdatingBrokerAgencyAccountOrProfile.new(given_task_name, double(:current_scope => nil)) }

  context "create_org_and_broker_agency_profile" do
    before(:each) do
      # allow(ENV).to receive(:[]).with("person_hbx_id").and_return(person.hbx_id)
      # allow(ENV).to receive(:[]).with("legal_name").and_return(organization.legal_name)
      # allow(ENV).to receive(:[]).with("fein").and_return(fein)
      # allow(ENV).to receive(:[]).with("defualt_general_agency_id").and_return(broker_agency_profile.default_general_agency_profile_id)
      # allow(ENV).to receive(:[]).with("npn").and_return(person.broker_role.npn)
      # allow(ENV).to receive(:[]).with("address_1").and_return(office_locations.address_1)
      # allow(ENV).to receive(:[]).with("address_2").and_return(office_locations.address_2)
      # allow(ENV).to receive(:[]).with("city").and_return(office_locations.city)
      # allow(ENV).to receive(:[]).with("state").and_return(office_locations.state)
      # allow(ENV).to receive(:[]).with("zip").and_return(office_locations.zip)
      # allow(ENV).to receive(:[]).with("area_code").and_return(office_locations_contact.area_code)
      # allow(ENV).to receive(:[]).with("number").and_return(office_locations_contact.number)
      # allow(ENV).to receive(:[]).with("market_kind").and_return(broker_agency_profile.market_kind)
      # # allow(ENV).to receive(:[]).with("broker_agency_profile_id").and_return(broker_agency_profile.id.to_s)
      # allow(ENV).to receive(:[]).with("action").and_return("create_org_and_broker_agency_profile")
      employer_profile.broker_agency_accounts << broker_agency_account
    end

    it "Should update the person broker_role id with with new broker_agency" do
      ClimateControl.modify person_hbx_id:person.hbx_id,
      legal_name: organization.legal_name,
      fein:fein,
      defualt_general_agency_id: broker_agency_profile.default_general_agency_profile_id,
      npn:person.broker_role.npn,
      address_1:office_locations.address_1,
      address_2:office_locations.address_2,
      city:office_locations.city,
      state:office_locations.state,
      zip:office_locations.zip,
      area_code:office_locations_contact.area_code,
      number:office_locations_contact.number,
      market_kind:broker_agency_profile.market_kind,
      action:'create_org_and_broker_agency_profile' do
        subject.migrate
        person.reload
        expect(person.broker_role.broker_agency_profile.organization.fein).to eq fein
      end
  end

  context "update_broker_role" do
      before(:each) do
        # allow(ENV).to receive(:[]).with("person_hbx_id").and_return(person.hbx_id)
        # allow(ENV).to receive(:[]).with("legal_name").and_return(organization.legal_name)
        # allow(ENV).to receive(:[]).with("fein").and_return(fein)
        # allow(ENV).to receive(:[]).with("defualt_general_agency_id").and_return(broker_agency_profile.default_general_agency_profile_id)
        # allow(ENV).to receive(:[]).with("npn").and_return(person.broker_role.npn)
        # allow(ENV).to receive(:[]).with("address_1").and_return(office_locations.address_1)
        # allow(ENV).to receive(:[]).with("address_2").and_return(office_locations.address_2)
        # allow(ENV).to receive(:[]).with("city").and_return(office_locations.city)
        # allow(ENV).to receive(:[]).with("state").and_return(office_locations.state)
        # allow(ENV).to receive(:[]).with("zip").and_return(office_locations.zip)
        # allow(ENV).to receive(:[]).with("area_code").and_return(office_locations_contact.area_code)
        # allow(ENV).to receive(:[]).with("number").and_return(office_locations_contact.number)
        # allow(ENV).to receive(:[]).with("market_kind").and_return('both')
        # allow(ENV).to receive(:[]).with("broker_agency_profile_id").and_return(broker_agency_profile.id.to_s)
        # allow(ENV).to receive(:[]).with("action").and_return("update_broker_role")
        employer_profile.broker_agency_accounts << broker_agency_account
      end

      it "Should update the person broker_role id with with new broker_agency" do
        ClimateControl.modify person_hbx_id:person.hbx_id,
        legal_name: organization.legal_name,
        fein:fein,
        defualt_general_agency_id: broker_agency_profile.default_general_agency_profile_id,
        npn:person.broker_role.npn,
        address_1:office_locations.address_1,
        address_2:office_locations.address_2,
        city:office_locations.city,
        state:office_locations.state,
        zip:office_locations.zip,
        area_code:office_locations_contact.area_code,
        number:office_locations_contact.number,
        market_kind:'both',
        broker_agency_profile_id: broker_agency_profile.id,
        action:'update_broker_role' do
            subject.migrate
            person.reload
            expect(person.broker_role.market_kind).to eq 'both'
        end
      end
    end
  end

  context 'update_family_broker_agency_account_with_writing_agent', dbclean: :before_each do
    let!(:given_task_name) { "updating_broker_agency_account_or_profile" }
    let!(:person) { FactoryBot.create(:person,:with_broker_role)}
    let!(:dummy_writing_agent_id) { "12345667" }
    let(:site)  { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let(:benefit_broker_agency_organization)   { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site) }
    let(:benefit_broker_agency_profile) { benefit_broker_agency_organization.broker_agency_profile }
    let(:writing_agent_id) { benefit_broker_agency_profile.primary_broker_role.id }
    let(:family) {FactoryBot.create(:family,:with_primary_family_member, person: person, broker_agency_accounts: [benefit_broker_agency_account])}
    let(:benefit_broker_agency_account) { BenefitSponsors::Accounts::BrokerAgencyAccount.new(benefit_sponsors_broker_agency_profile_id: benefit_broker_agency_profile.id, writing_agent_id: dummy_writing_agent_id, is_active: true, start_on: TimeKeeper.date_of_record) }

    it 'should update the broker agency account with correct writing agent' do
      ClimateControl.modify org_fein: benefit_broker_agency_organization.fein,
        hbx_id: person.hbx_id,
        action: 'update_family_broker_agency_account_with_writing_agent' do
        expect(family.broker_agency_accounts.first.writing_agent_id).to eq dummy_writing_agent_id
        subject.migrate
        family.reload
        expect(family.broker_agency_accounts.first.writing_agent_id).to eq writing_agent_id
      end
    end

    it 'should return if fein is not passed' do
      ClimateControl.modify org_fein: "",
                            hbx_id: person.hbx_id,
                            action: 'update_family_broker_agency_account_with_writing_agent' do
        expect( subject.migrate).to eq 'Fein not found'
      end
    end

    it 'should return if organization is not found' do
      ClimateControl.modify org_fein: "12345",
                            hbx_id: person.hbx_id,
                            action: 'update_family_broker_agency_account_with_writing_agent' do
        expect(subject.migrate).to eq 'Unable to find organization with FEIN'
      end
    end
  end
end
