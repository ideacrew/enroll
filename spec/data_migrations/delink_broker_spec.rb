require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "delink_broker")

describe DelinkBroker do
  
  let(:given_task_name) { "delink_broker" }
  let(:person) { FactoryGirl.create(:person,:with_broker_role)}
  let(:employer_profile) { FactoryGirl.create(:employer_profile)}
  subject { DelinkBroker.new(given_task_name, double(:current_scope => nil)) }

  before(:each) do
    # @broker_agency_id = broker_agency.id
    allow(ENV).to receive(:[]).with("person_hbx_id").and_return(person.hbx_id)
    allow(ENV).to receive(:[]).with("legal_name").and_return("legal_name")
    allow(ENV).to receive(:[]).with("fein").and_return("fein")
    allow(ENV).to receive(:[]).with("organization_ids_to_move").and_return([employer_profile.organization.id])

  end

  it "Should update the person broker_role id with with new broker_agency" do
    old_broker_agency_profile_id=person.broker_role.broker_agency_profile_id.to_s
    subject.migrate
    person.reload
    expect(old_broker_agency_profile_id).not_to eq(person.broker_role.broker_agency_profile_id.to_s)
  end
end
