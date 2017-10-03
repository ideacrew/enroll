require 'rails_helper'
describe "shared/_carrier_contact_information.html.erb" do
  let(:plan) { FactoryGirl.build_stubbed(:plan) }
  before :each do
    render partial: "shared/carrier_contact_information", locals: { plan: plan }
  end
  it "should display the carrier name and number" do
    expect(rendered).to match plan.carrier_profile.legal_name
    expect(rendered).to include(plan.carrier_profile.carrier_contacts.first.us_formatted_number)
  end
end
