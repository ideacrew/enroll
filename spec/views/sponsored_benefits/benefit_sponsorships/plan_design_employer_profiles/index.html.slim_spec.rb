require 'rails_helper'

RSpec.describe "benefit_sponsorships/plan_design_employer_profiles/index", type: :view do
  before(:each) do
    assign(:benefit_sponsorships_plan_design_employer_profiles, [
      BenefitSponsorships::PlanDesignEmployerProfile.create!(
        :entity_kind => "Entity Kind",
        :sic_code => "Sic Code",
        :legal_name => "Legal Name",
        :dba => "Dba",
        :entity_kind => "Entity Kind"
      ),
      BenefitSponsorships::PlanDesignEmployerProfile.create!(
        :entity_kind => "Entity Kind",
        :sic_code => "Sic Code",
        :legal_name => "Legal Name",
        :dba => "Dba",
        :entity_kind => "Entity Kind"
      )
    ])
  end

  it "renders a list of benefit_sponsorships/plan_design_employer_profiles" do
    render
    assert_select "tr>td", :text => "Entity Kind".to_s, :count => 2
    assert_select "tr>td", :text => "Sic Code".to_s, :count => 2
    assert_select "tr>td", :text => "Legal Name".to_s, :count => 2
    assert_select "tr>td", :text => "Dba".to_s, :count => 2
    assert_select "tr>td", :text => "Entity Kind".to_s, :count => 2
  end
end
