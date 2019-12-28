require "rails_helper"

require File.join(Rails.root, "app", "data_migrations", "correct_plan_year_end_date")
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

describe CorrectPlanYearEndDate, dbclean: :after_each do

  let(:given_task_name) { "correct_plan_year_end_date" }
  subject { CorrectPlanYearEndDate.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "correct_plan_year_end_date", dbclean: :after_each do

    include_context "setup benefit market with market catalogs and product packages"
    include_context "setup initial benefit application"

    before do
      initial_application.effective_period = Date.new(2019, 1, 1)..Date.new(2019, 9, 30)
      initial_application.save!(validate: false)
    end

    it "should correct the end date on the plan year" do
      ClimateControl.modify fein: abc_organization.fein, py_effective_on: initial_application.effective_period.min.strftime("%m/%d/%Y") do
        expect(initial_application.effective_period.max).to eq(Date.new(2019, 9, 30))
        subject.migrate
        initial_application.reload
        expect(initial_application.effective_period.max).to eq(Date.new(2019, 12, 31))
      end
    end
  end
end

