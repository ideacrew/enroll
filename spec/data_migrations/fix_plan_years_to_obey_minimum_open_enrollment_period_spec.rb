require "rails_helper"
require "pry"

require File.join(Rails.root, "app", "data_migrations", "fix_plan_years_to_obey_minimum_open_enrollment_period")
describe FixPlanYearsToObeyMinimumOpenEnrollmentPeriod do

    let(:given_task_name) { "fix_plan_years_to_obey_minimum_open_enrollment_period" }
    subject { FixPlanYearsToObeyMinimumOpenEnrollmentPeriod.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "changing new hire rule" do

    context " changing effective on kind" do                                
      let(:organization)      { FactoryGirl.create(:organization, fein: "123456789")}
      let(:plan_year)         { FactoryGirl.build(:plan_year, open_enrollment_start_on: Date.new(2016, 2, 8), open_enrollment_end_on: Date.new(2016, 2, 10), start_on: Date.new(2016, 3, 1)) }
      let(:employer_profile)  { FactoryGirl.build(:employer_profile, organization: organization, plan_years: [plan_year]) }
        
      before(:each) do
        employer_profile.save(validate: false) # Forcing the validation because we want an employer profile with an invalid plan year for the test case.
        allow(ENV).to receive(:[]).with("fein").and_return("123456789")
      end

      it "will change the effective on kind for the benefit group from date_of_hire to first_of_month" do
        subject.migrate
        plan_year.reload
        expect(plan_year.open_enrollment_end_on.mjd - plan_year.open_enrollment_start_on.mjd).to eq 4
      end
    end
  end


end