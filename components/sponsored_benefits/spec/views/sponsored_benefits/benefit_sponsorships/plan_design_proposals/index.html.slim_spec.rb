require 'rails_helper'

RSpec.describe "benefit_sponsorships/plan_design_proposals/index", type: :view do
  before(:each) do
    assign(:benefit_sponsorships_plan_design_proposals, [
      BenefitSponsorships::PlanDesignProposal.create!(),
      BenefitSponsorships::PlanDesignProposal.create!()
    ])
  end

  it "renders a list of benefit_sponsorships/plan_design_proposals" do
    render
  end
end
