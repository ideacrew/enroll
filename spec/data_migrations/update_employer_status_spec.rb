require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_employer_status")


describe UpdateEmployerStatus, dbclean: :after_each do

  let(:given_task_name) { "employer_status_to_enrolled" }
  subject { UpdateEmployerStatus.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "updating aasm_state of the employer profile to enrolled", dbclean: :after_each do
    let(:plan_year){ FactoryBot.build(:plan_year, aasm_state: "application_ineligible") }
    let(:employer_profile){ FactoryBot.build(:employer_profile, aasm_state:'registered', plan_years: [plan_year]) }
    let(:organization)  {FactoryBot.create(:organization,employer_profile:employer_profile)}

    it "should update aasm_state of employer profile" do
      ClimateControl.modify fein:organization.fein, plan_year_start_on:"#{plan_year.start_on}" do
        subject.migrate
        employer_profile.reload
        expect(employer_profile.aasm_state).to eq "enrolled"
      end
    end

    it "should update aasm_state of plan year" do
      ClimateControl.modify fein:organization.fein, plan_year_start_on:"#{plan_year.start_on}" do
        subject.migrate
        plan_year.reload
        expect(plan_year.aasm_state).to eq "enrolled"
      end
    end

    it "should not update aasm_state of employer profile for invalid state" do
      ClimateControl.modify fein:organization.fein, plan_year_start_on:"#{plan_year.start_on}" do
        employer_profile.aasm_state='ineligile'
        employer_profile.save
        subject.migrate
        employer_profile.reload
        expect(employer_profile.aasm_state).to eq "ineligile"
      end
    end

    it "should not should update aasm_state of plan year when ENV['plan_year_start_on'] is empty" do
      ClimateControl.modify fein:organization.fein, plan_year_start_on:"" do
        subject.migrate
        plan_year.reload
        expect(plan_year.aasm_state).to eq "application_ineligible"
      end
    end
  end
end
