require 'rails_helper'

RSpec.describe "benefit_sponsorships/plan_design_proposals/new", type: :view do
  before(:each) do
    assign(:benefit_sponsorships_plan_design_proposal, BenefitSponsorships::PlanDesignProposal.new())
  end

  it "renders new benefit_sponsorships_plan_design_proposal form" do
    render

    assert_select "form[action=?][method=?]", benefit_sponsorships_plan_design_proposals_path, "post" do
    end
  end
end
