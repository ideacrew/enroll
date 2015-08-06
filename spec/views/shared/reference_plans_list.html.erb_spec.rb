require 'rails_helper'

describe "shared/_reference_plans_list.html.erb" do
  let(:mock_benefit_group) { double(:plan_option_kind => nil, :persisted? => false, :carrier_for_elected_plan => nil, :metal_level_for_elected_plan => nil, :reference_plan_id => nil )}
  let(:mock_plan_year) { double(:metal_level_plans_for => []) }

  before :each do
    helper = Object.new.extend ActionView::Helpers::FormHelper
    helper.extend ActionDispatch::Routing::PolymorphicRoutes
    helper.extend ActionView::Helpers::FormOptionsHelper
    mock_form = ActionView::Helpers::FormBuilder.new(:benefit_group, mock_benefit_group, helper, {})
    assign :carriers_array, []
    assign :carrier_names, {}
    assign :plan_year, mock_plan_year
    render "shared/reference_plans_list", :f => mock_form
  end

  it "should have a selection option for platinum" do
    expect(rendered).to have_selector("option[value='platinum']")
  end

  it "should have a selection option for gold" do
    expect(rendered).to have_selector("option[value='gold']")
  end

  it "should have a selection option for silver" do
    expect(rendered).to have_selector("option[value='silver']")
  end

  it "should have a selection option for bronze" do
    expect(rendered).to have_selector("option[value='bronze']")
  end

  it "should not have a selection option for dental" do
    expect(rendered).not_to have_selector("option[value='dental']")
  end

  it "should not have a selection option for catastrophic" do
    expect(rendered).not_to have_selector("option[value='catastrophic']")
  end
end
