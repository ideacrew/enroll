require "rails_helper"

RSpec.describe "insured/plan_shoppings/plans.js.erb" do
  before :each do
    assign :plans, []
    render template: "insured/plan_shoppings/plans.js.erb"
  end

  it "should call aptc" do
    expect(rendered).to match /aptc/
    expect(rendered).to match /elected_pct/
    expect(rendered).to match /updatePlanCost/
  end
end
