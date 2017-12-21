require 'rails_helper'

RSpec.describe "benefit_sponsorships/plan_design_proposals/edit", type: :view do
  before(:each) do
    @benefit_sponsorships_plan_design_proposal = assign(:benefit_sponsorships_plan_design_proposal, BenefitSponsorships::PlanDesignProposal.create!())
  end

  it "renders the edit benefit_sponsorships_plan_design_proposal form" do
    render

    assert_select "form[action=?][method=?]", benefit_sponsorships_plan_design_proposal_path(@benefit_sponsorships_plan_design_proposal), "post" do
    end
  end
end
