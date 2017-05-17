require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "remove_census_employees")

describe RemoveCensusEmployees do

  let(:given_task_name) { "remove_census_employees" }
  subject { RemoveCensusEmployees.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "deleting census employees" do
    let(:organization) { FactoryGirl.create(:organization)}
    let(:employer_profile)  { FactoryGirl.create(:employer_profile, organization: organization)}

    before(:each) do
      3.times{|i| FactoryGirl.create :census_employee, employer_profile: employer_profile, dob: TimeKeeper.date_of_record - 30.years + i.days }
      allow(ENV).to receive(:[]).with("fein").and_return(organization.fein)
      allow(Organization).to receive(:where).and_return([organization])
      allow(organization).to receive(:employer_profile).and_return(employer_profile)
    end

    it "should remove census employees from an employer profile" do
      subject.migrate
      expect(organization.employer_profile.census_employees.count).to eq 0
    end

  end
end