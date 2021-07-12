require 'rails_helper'

RSpec.describe "general_agencies/profiles/_staffs.html.erb" do
  let(:staff) { FactoryBot.create(:general_agency_staff_role) }
  before :each do
    assign :staffs, [staff]
    EnrollRegistry[:general_agency].feature.stub(:is_enabled).and_return(true)
    Enroll::Application.reload_routes!
    render template: "general_agencies/profiles/_staffs.html.erb"
  end

  it 'should have title' do
    expect(rendered).to have_selector('h3', text: 'General Agency Staff')
  end

  it 'should show staff info' do
    expect(rendered).to have_selector('a', text: "#{staff.person.first_name} #{staff.person.last_name}")
  end
end
