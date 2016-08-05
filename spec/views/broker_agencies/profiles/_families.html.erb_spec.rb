require 'rails_helper'

RSpec.describe "broker_agencies/profiles/_families.html.erb"  do |variable|
  before :each do
    stub_template "_families_table_for_broker.html.erb" => ''
    @page_alphabets = ['XXX', 'YYY']
    @broker_agency_profile = FactoryGirl.create(:broker_agency_profile)
    render template: "broker_agencies/profiles/_families.html.erb" 
  end

  it 'should have title Families' do
    expect(rendered).to have_selector('h3', text: 'Families')
  end

  it 'should show page alphabet links' do
    expect(rendered).to have_selector('a', text: 'XXX')
    expect(rendered).to have_selector('a', text: 'YYY')
    expect(rendered).to have_link("XXX", href:"/broker_agencies/profiles/family_index?page=XXX&id=#{@broker_agency_profile.id}")
    expect(rendered).to have_link("YYY", href:"/broker_agencies/profiles/family_index?page=YYY&id=#{@broker_agency_profile.id}")
  end

  it 'should not reference enrollment' do
    expect(rendered).not_to have_selector('p', text: 'working on an enrollment')
  end
end