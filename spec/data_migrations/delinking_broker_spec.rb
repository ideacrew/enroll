require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "delinking_broker")

describe DelinkingBroker do
  
  let(:given_task_name) { "delinking_broker" }
  let(:person) { FactoryGirl.create(:person,:with_broker_role)}
  let(:organization1) {FactoryGirl.create(:organization)}
  let(:organization) {FactoryGirl.create(:organization)}
  let(:employer_profile) { FactoryGirl.create(:employer_profile, organization: organization)}
  let(:broker_agency_profile) {FactoryGirl.create(:broker_agency_profile, organization: organization1)}
  let(:office_locations_contact) {FactoryGirl.build(:phone, kind: "work")}
  let(:office_locations) {FactoryGirl.build(:address, kind: "branch")}
  let(:broker_agency_account) {FactoryGirl.create(:broker_agency_account, broker_agency_profile: broker_agency_profile, writing_agent_id: person.broker_role.id, is_active: true, employer_profile: employer_profile)}
  subject { DelinkingBroker.new(given_task_name, double(:current_scope => nil)) }

  before(:each) do
    allow(ENV).to receive(:[]).with("person_hbx_id").and_return(person.hbx_id)
    allow(ENV).to receive(:[]).with("legal_name").and_return("legal_name")
    allow(ENV).to receive(:[]).with("fein").and_return("fein")
    allow(ENV).to receive(:[]).with("address_1").and_return("office_locations.address_1")
    allow(ENV).to receive(:[]).with("address_2").and_return("office_locations.address_2")
    allow(ENV).to receive(:[]).with("city").and_return("office_locations.city")
    allow(ENV).to receive(:[]).with("state").and_return("office_locations.state")
    allow(ENV).to receive(:[]).with("zip").and_return("office_locations.zip")
    allow(ENV).to receive(:[]).with("area_code").and_return("office_locations_contact.area_code")
    allow(ENV).to receive(:[]).with("number").and_return("office_locations_contact.number")
    allow(ENV).to receive(:[]).with("market_kind").and_return("broker_agency_profile.market_kind")
    allow(ENV).to receive(:[]).with("organization_ids_to_move").and_return(employer_profile.organization.id.to_s)
    employer_profile.broker_agency_accounts << broker_agency_account
  end

  it "Should update the person broker_role id with with new broker_agency" do
    subject.migrate
    person.reload
    expect(office_locations_contact.number).to eq "1111120"
  end
end
