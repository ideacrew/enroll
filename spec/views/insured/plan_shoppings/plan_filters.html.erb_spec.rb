require "rails_helper"

RSpec.describe "insured/_plan_filters.html.erb" do
  before :each do
    assign(:carriers, Array.new)
    assign(:max_total_employee_cost, 1000)
    assign(:max_deductible, 998)
    render :template => "insured/plan_shoppings/_plan_filters.html.erb"
  end

  it 'should display filter selections' do
    expect(rendered).to match /Hsa Eligibility/ 
    expect(rendered).to match /Carrier/
    expect(rendered).to have_selector('select', count: 2)
  end

  it "should have Premium amount search" do
    expect(rendered).to match /Premium Amount/
    expect(rendered).to have_selector("input[value='1000']", count: 2)
  end

  it "should have Deductible Amount search" do
    expect(rendered).to match /Deductible Amount/
    expect(rendered).to have_selector("input[value='998']", count: 2)
  end
end
