require "rails_helper"

RSpec.describe "insured/_plan_filters.html.erb" do
  before :each do
    assign(:carriers, Array.new)
    render :template => "insured/plan_shoppings/_plan_filters.html.erb"
  end

  it 'should display filter selections' do
    expect(rendered).to match /Hsa Eligibility/ 
    expect(rendered).to match /Carrier/
    expect(rendered).to have_selector('select', count: 2)
  end
end
