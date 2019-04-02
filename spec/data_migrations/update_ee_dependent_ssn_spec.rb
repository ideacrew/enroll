require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_ee_dependent_ssn")

describe UpdateEeDependentSSN, dbclean: :after_each do

  let(:given_task_name) { "update_ee_dependent_ssn" }
  subject { UpdateEeDependentSSN.new(given_task_name, double(:current_scope => nil)) }
  let(:census_employee)  { FactoryBot.create(:census_employee)}
  let(:census_dependent) { CensusDependent.new(first_name:'David', last_name:'Henry', ssn: "", employee_relationship: "spouse", dob: TimeKeeper.date_of_record - 30.years, gender: "male") }
  let(:census_env_params) {{ce_id: census_employee.id, dep_id: census_dependent.id, dep_ssn: census_dependent.ssn}}

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "update census dependent ssn" do
   it "should be valid" do
     expect(census_employee.valid?).to be_truthy
   end

   it "if census_dependents are present" do
     census_employee.census_dependents = [census_dependent]
    expect(census_employee.census_dependents.present?).to be_truthy
   end

    it "if census_dependents are not present" do
      expect(census_employee.census_dependents.present?).to be_falsey
    end

    it "if given dependent is not found" do
      census_employee.census_dependents = []
      expect(census_employee.census_dependents.first).to be_falsey
   end 
  end

  describe "when Cron job recives" do 
    context "env_params" do
      it "allow dependent ssn's to be updated to nil" do
        ClimateControl.modify census_env_params do 
          census_employee.census_dependents = [census_dependent]
          subject.migrate
          census_employee.reload
          expect(census_employee.census_dependents.first.ssn).to match(nil)
        end
      end

      it "allow dependent ssn's to be updated" do
        ClimateControl.modify census_env_params do 
          census_employee.census_dependents = [census_dependent]
          census_employee.census_dependents.first.update_attributes!(ssn: "123456789")
          subject.migrate
          census_employee.reload
          expect(census_employee.census_dependents.first.ssn).to match("123456789")
        end
      end
    end
  end
end
