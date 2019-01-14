require "rails_helper"

RSpec.describe "employers/employer_profiles/_menu.html.erb" do
  let(:employer_profile) { FactoryBot.create(:employer_profile) }

  before :each do
    assign(:employer_profile, employer_profile)
    render "employers/employer_profiles/menu"
  end

  it "should display the main menu" do
    expect(rendered).to have_selector('a[href="#profile"]', text: 'Profile')
    expect(rendered).to have_selector('a[href="#benefits"]', text: 'Benefits')
    expect(rendered).to have_selector('a[href="#employees"]', text: 'Employees')
    expect(rendered).to have_selector('a[href="#broker_agency"]', text: 'Broker Agency')
    expect(rendered).to have_selector('a[href="#documents"]', text: 'Documents')
    expect(rendered).to have_selector("a[href='/employers/employer_profiles/inbox?id=#{employer_profile.id}']", text: 'Inbox')
  end
end
