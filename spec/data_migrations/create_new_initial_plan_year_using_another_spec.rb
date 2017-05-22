require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "create_new_initial_plan_year_using_another")

describe CreateNewInitialPlanYearUsingAnother do
  let(:given_task_name) { "create_new_initial_plan_year_using_another" }
  subject { CreateNewInitialPlanYearUsingAnother.new(given_task_name, double(:current_scope => nil)) }

  describe "create_initial_plan_year" do
    let(:benefit_group) { FactoryGirl.create(:benefit_group)}
    let(:old_plan_year) { benefit_group.plan_year }
    let(:employer_profile) { FactoryGirl.create(:employer_profile, {:plan_years=>[old_plan_year]}) }
    let(:organization) { employer_profile.organization}
    let(:start_on) { "01012017" }

    it "creates a new plan year" do
      new_plan_year = subject.create_initial_plan_year(organization, old_plan_year, "01012017")
      expect(employer_profile.plan_years.length).to be 2
      expect(employer_profile.plan_years).to include(new_plan_year)
      expect(new_plan_year.start_on.strftime("%m%d%Y")).to include(start_on)
    end
  end
end
