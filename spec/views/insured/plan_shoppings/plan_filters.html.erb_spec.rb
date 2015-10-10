require "rails_helper"

RSpec.describe "insured/_plan_filters.html.erb" do
  context "without consumer_role" do
    let(:person) {double(has_active_consumer_role?: false)}

    before :each do
      assign(:person, person)
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

  context "with consumer_role and tax_household" do
    let(:person) {double(has_active_consumer_role?: true)}
    let(:hbx_enrollment) {double(id: '123')}

    before :each do
      assign(:person, person)
      assign(:carriers, Array.new)
      assign(:max_total_employee_cost, 1000)
      assign(:max_deductible, 998)
      assign(:max_aptc, 330)
      assign(:hbx_enrollment, hbx_enrollment)
      assign(:tax_household, true)
      assign(:selected_aptc_pct, 0.85)
      render :template => "insured/plan_shoppings/_plan_filters.html.erb"
    end

    it "should have aptc area" do
      expect(rendered).to have_selector('div.aptc')
      expect(rendered).to have_selector('input#max_aptc')
      expect(rendered).to have_selector('input#set_elected_pct_url')
      expect(rendered).to have_selector("input[name='elected_pct']")
    end

    it "should have Aptc used" do
      expect(rendered).to match /Used/
      expect(rendered).to have_selector("input#aptc-used")
    end

    it "should have aptc available" do
      expect(rendered).to match /APTC/
      expect(rendered).to match /Available/
      expect(rendered).to match /330/
    end

    it "should have selected aptc pct amount" do
      expect(rendered).to match /85/
      expect(rendered).to have_selector("input#aptc-used[value='280.50']")
    end
  end

  context "with consumer_role but without tax_household" do
    let(:person) {double(has_active_consumer_role?: true)}
    let(:hbx_enrollment) {double(id: '123')}

    before :each do
      assign(:person, person)
      assign(:carriers, Array.new)
      assign(:max_total_employee_cost, 1000)
      assign(:hbx_enrollment, hbx_enrollment)
      assign(:tax_household, nil)
      render :template => "insured/plan_shoppings/_plan_filters.html.erb"
    end

    it "should not have aptc area" do
      expect(rendered).not_to have_selector('div.aptc')
      expect(rendered).not_to have_selector('input#max_aptc')
      expect(rendered).not_to have_selector('input#set_elected_pct_url')
      expect(rendered).not_to have_selector("input[name='elected_pct']")
    end
  end
end
