require 'rails_helper'

RSpec.describe "broker_agencies/profiles/_general_agencies.html.erb" do
  let(:general_agency_profile) { FactoryGirl.create(:general_agency_profile) }
  let(:broker_agency_profile) { FactoryGirl.create(:broker_agency_profile) }

  before :each do
    assign :general_agency_profiles, [general_agency_profile]
    assign :broker_agency_profile, broker_agency_profile
    render template: "broker_agencies/profiles/_general_agencies.html.erb" 
  end

  it 'should have title' do
    expect(rendered).to have_selector('h3', text: 'General Agencies')
  end

  it "should have button of clear default ga" do
    expect(rendered).to have_selector('a', text: 'Clear Default GA')
  end

  it "should have general_agency_profile" do
    expect(rendered).to have_selector('td', text: "#{general_agency_profile.dba}")
    expect(rendered).to have_selector('td', text: "#{general_agency_profile.fein}")
  end

  it "should have link of set default ga" do
    expect(rendered).to have_selector('a', text: 'Set Default GA')
  end
end
