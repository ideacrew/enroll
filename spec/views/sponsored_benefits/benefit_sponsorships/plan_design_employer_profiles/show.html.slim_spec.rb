require 'rails_helper'

RSpec.describe "benefit_sponsorships/plan_design_employer_profiles/show", type: :view do
  before(:each) do
    @benefit_sponsorships_plan_design_employer_profile = assign(:benefit_sponsorships_plan_design_employer_profile, BenefitSponsorships::PlanDesignEmployerProfile.create!(
      :entity_kind => "Entity Kind",
      :sic_code => "Sic Code",
      :legal_name => "Legal Name",
      :dba => "Dba",
      :entity_kind => "Entity Kind"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Entity Kind/)
    expect(rendered).to match(/Sic Code/)
    expect(rendered).to match(/Legal Name/)
    expect(rendered).to match(/Dba/)
    expect(rendered).to match(/Entity Kind/)
  end
end
