require 'rails_helper'
RSpec.describe "shared/_premium_reports_widget.html.erb" do
  let(:plan_year) { FactoryGirl.build_stubbed(:plan_year) }

  context "with active plan year billing date" do
    let(:employer_profile) { FactoryGirl.build_stubbed(:employer_profile, plan_years: [plan_year]) }
    before :each do
      assign(:employer_profile, employer_profile)
      render "shared/premium_reports_widget"
    end

    it "should display the widget" do
      expect(rendered).to have_selector('strong', text: /Enrollment Report/i)
    end
  end

  context "without active plan year" do
    let(:employer_profile) { FactoryGirl.build_stubbed(:employer_profile) }
    before :each do
      assign(:employer_profile, employer_profile)
      allow(employer_profile).to receive(:billing_plan_year).and_return([])
      render "shared/premium_reports_widget"
    end

    it "should not display the widget" do
      expect(rendered).to_not have_selector('strong', text: /Enrollment Report/i)
    end
  end

end
