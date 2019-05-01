require "rails_helper"

RSpec.describe "broker_agencies/broker_roles/_search_broker_agency.html.erb" do
  let(:organization) { FactoryGirl.create(:organization) }
  let(:broker_role) {FactoryGirl.create(:broker_role)}
  let(:broker_agency_profile) { FactoryGirl.create(:broker_agency_profile, primary_broker_role_id: broker_role.id,  organization: organization) }

  before :each do
    assign :broker_agency_profiles, [broker_agency_profile]
    render "broker_agencies/broker_roles/search_broker_agency"
  end

  it "should have npn" do
    expect(rendered).to match /NPN/
    expect(rendered).to match /#{broker_agency_profile.primary_broker_role.npn}/
  end

  it "should have legal name" do
    expect(rendered).to match /Legal Name/
    expect(rendered).to match /#{broker_agency_profile.legal_name}/
  end

  it "should have primary broker name" do
    expect(rendered).to match /Primary Broker Name/
  end
end
