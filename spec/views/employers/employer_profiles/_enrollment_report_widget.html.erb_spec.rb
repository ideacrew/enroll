require 'rails_helper'
RSpec.describe "employers/employer_profiles/_enrollment_report_widget.html.erb" do
  let(:plan_year) { FactoryGirl.build_stubbed(:plan_year) }

  context "with active plan year billing date" do
    let(:employer_profile) { FactoryGirl.build_stubbed(:employer_profile, plan_years: [plan_year]) }
    before :each do
      assign(:employer_profile, employer_profile)
      render "employers/employer_profiles/enrollment_report_widget"
    end
  end

  context "without active plan year" do
    let(:employer_profile) { FactoryGirl.build_stubbed(:employer_profile) }
    before :each do
      assign(:employer_profile, employer_profile)
      allow(employer_profile).to receive(:billing_plan_year).and_return([])
      render "employers/employer_profiles/enrollment_report_widget"
    end

    it "should not display the widget" do
      expect(rendered).to_not have_selector('strong', text: /Enrollment Report/i)
    end
  end

end