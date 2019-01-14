require "rails_helper"

RSpec.describe "broker_agencies/broker_roles/_search_broker_agency.html.erb" do
  let(:organization) { FactoryBot.create(:organization) }
  let(:broker_agency_profile) { FactoryBot.create(:broker_agency_profile, organization: organization) }

  before :each do
    assign :broker_agency_profiles, [broker_agency_profile]
    render "broker_agencies/broker_roles/search_broker_agency"
  end

  it "should have fein" do
    expect(rendered).to match /FEIN/
    expect(rendered).to match /#{broker_agency_profile.fein}/
  end

  it "should have legal name" do
    expect(rendered).to match /Legal Name/
    expect(rendered).to match /#{broker_agency_profile.legal_name}/
  end

  it "should have primary broker name" do
    expect(rendered).to match /Primary Broker Name/
  end
end
