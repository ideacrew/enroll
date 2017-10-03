require 'rails_helper'
describe "shared/_carrier_contact_information.html.erb" do
  let(:plan) { FactoryGirl.build_stubbed(:plan) }
  let (:carrier_contacts) { FactoryGirl.create(:carrier_contact) }
  before :each do
    allow(plan.carrier_profile).to receive(:carrier_contacts).and_return([carrier_contacts])
    render partial: "shared/carrier_contact_information", locals: { plan: plan }
  end
  it "should display the carrier name and number" do
    expect(rendered).to match plan.carrier_profile.legal_name
    expect(rendered).to include("+1-877-856-2430")
  end
end
