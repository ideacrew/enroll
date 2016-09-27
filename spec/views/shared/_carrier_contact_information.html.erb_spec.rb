require 'rails_helper'
describe "shared/_carrier_contact_information.html.erb" do
  let(:plan) { FactoryGirl.build_stubbed(:plan) }
  let(:organization) {FactoryGirl.create(:organization, legal_name:"Kaiser")}
  let(:carrier_profile) {FactoryGirl.create(:carrier_profile, organization: organization)}
  let(:plan1) {FactoryGirl.create(:plan, carrier_profile: carrier_profile)}
  before :each do
    render partial: "shared/carrier_contact_information", locals: { plan: plan }
  end
  it "should display the carrier name and number" do
    expect(rendered).to match plan.carrier_profile.legal_name
    expect(rendered).to match("1-877-856-2430")
  end
  it "should have carrier name Kaiser and it's number" do
    render partial: "shared/carrier_contact_information", locals: { plan: plan1 }
    expect(rendered).to match plan1.carrier_profile.legal_name
    expect(rendered).to match("1-844-524-7370")
  end
end
