require 'rails_helper'

describe "employers/plan_years/reference_plan_summary.js.erb" do
  let(:employer_profile){ FactoryBot.build_stubbed(:employer_profile) }
  let(:plan) { FactoryBot.build_stubbed(:plan) }
  before(:each) do
    assign(:employer_profile, employer_profile)
    assign(:plan, plan)
    assign(:employer_profile_id, employer_profile.id)
    @plan = plan
    @visit_types = []
    @coverage_kind = 'health'
    @hios_id = '1203940129312'
    @reference_plan_id = plan.id
    @employer_profile_id = employer_profile.id
    @start_on = 2016
  end

  before :each do
    assign(:employer_profile, employer_profile)
    assign(:plan, plan)
    render template: "employers/plan_years/reference_plan_summary.js.erb"
  end

  it "should display plan name and carrier in modal title" do
    expect(rendered).to match /BlueChoice/
    expect(rendered).to match /#{@plan.carrier_profile.legal_name}/
  end

  it "should display more details tite when details are present" do
    @details = 'details'
    expect(rendered).to match /BlueChoice/
    expect(rendered).to match /#{@plan.carrier_profile.legal_name}/
    expect(rendered).to match /More Details/
  end

end
