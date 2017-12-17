require 'rails_helper'

RSpec.describe "benefit_sponsorships/plan_design_employer_profiles/new", type: :view do
  before(:each) do
    assign(:benefit_sponsorships_plan_design_employer_profile, BenefitSponsorships::PlanDesignEmployerProfile.new(
      :entity_kind => "MyString",
      :sic_code => "MyString",
      :legal_name => "MyString",
      :dba => "MyString",
      :entity_kind => "MyString"
    ))
  end

  it "renders new benefit_sponsorships_plan_design_employer_profile form" do
    render

    assert_select "form[action=?][method=?]", benefit_sponsorships_plan_design_employer_profiles_path, "post" do

      assert_select "input#benefit_sponsorships_plan_design_employer_profile_entity_kind[name=?]", "benefit_sponsorships_plan_design_employer_profile[entity_kind]"

      assert_select "input#benefit_sponsorships_plan_design_employer_profile_sic_code[name=?]", "benefit_sponsorships_plan_design_employer_profile[sic_code]"

      assert_select "input#benefit_sponsorships_plan_design_employer_profile_legal_name[name=?]", "benefit_sponsorships_plan_design_employer_profile[legal_name]"

      assert_select "input#benefit_sponsorships_plan_design_employer_profile_dba[name=?]", "benefit_sponsorships_plan_design_employer_profile[dba]"

      assert_select "input#benefit_sponsorships_plan_design_employer_profile_entity_kind[name=?]", "benefit_sponsorships_plan_design_employer_profile[entity_kind]"
    end
  end
end
