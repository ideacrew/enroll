require 'rails_helper'

describe "shared/custom_dental_offered_plans_modal.html.erb" do
  let(:employer_profile) { FactoryBot.build_stubbed(:employer_profile) }
  let(:plan_year) { FactoryBot.build_stubbed(:plan_year) }
  let(:benefit_group) { FactoryBot.build_stubbed(:benefit_group, :with_valid_dental, plan_year: plan_year ) }
  let(:plan) { FactoryBot.build_stubbed(:plan) }

  before :each do
    render :partial => "shared/custom_dental_offered_plans_modal.html.erb", :locals => {:bg => benefit_group}
  end

  it "should display the modal title" do
    expect(rendered).to have_selector("h4", text: "Offered Plans")
  end

  it "should display 2 td's for elected dental plan" do
    expect(rendered).to have_selector("td", count: benefit_group.elected_dental_plan_ids.count*2)
  end

end
