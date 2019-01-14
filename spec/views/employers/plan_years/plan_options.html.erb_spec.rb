require "rails_helper"

RSpec.describe "employers/plan_years/_plan_options.html.erb" do
  let(:organization) {FactoryBot.create(:organization)}
  let(:carrier_profile) {FactoryBot.create(:carrier_profile, organization: organization)}
  let(:plan) {FactoryBot.create(:plan, carrier_profile: carrier_profile)}

  before :each do
    carriers = {}
    carriers[carrier_profile.id.to_s] = carrier_profile.legal_name

    assign(:plans, [plan])
    assign(:carrier_names, carriers)
    render :template => "employers/plan_years/_plan_options.html.erb"
  end

  it "should show default option" do
    expect(rendered).to have_selector("option", text: "SELECT REFERENCE PLAN")
  end

  it "should show plan option" do
    expect(rendered).to have_content("#{carrier_profile.legal_name} - #{plan.name}")
    expect(rendered).to have_selector(:option, text: "#{carrier_profile.legal_name} - #{plan.name}")
  end
end
