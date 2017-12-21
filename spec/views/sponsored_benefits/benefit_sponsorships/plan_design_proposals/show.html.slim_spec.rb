require 'rails_helper'

RSpec.describe "benefit_sponsorships/plan_design_proposals/show", type: :view do
  before(:each) do
    @benefit_sponsorships_plan_design_proposal = assign(:benefit_sponsorships_plan_design_proposal, BenefitSponsorships::PlanDesignProposal.create!())
  end

  it "renders attributes in <p>" do
    render
  end
end
