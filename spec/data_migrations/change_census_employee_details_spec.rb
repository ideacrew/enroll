require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "change_census_employee_details")

describe ChangeCensusEmployeeDetails, dbclean: :after_each do

  let(:given_task_name) { "change_census_employee_details" }
  subject { ChangeCensusEmployeeDetails.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end


  describe "update_terminated_on" do
    let(:census_employee)     { FactoryGirl.create(:census_employee, :employment_terminated_on => TimeKeeper.date_of_record - 1.month)}
    let(:terminated_on)     { TimeKeeper.date_of_record }

    it "should change the terminated_on date" do
      subject.send(:update_terminated_on, census_employee, terminated_on)
      expect(census_employee.employment_terminated_on).to eq(terminated_on)
    end
  end

  describe "update_enrollments" do
    let(:census_employee)     { FactoryGirl.create(:census_employee, :employment_terminated_on => TimeKeeper.date_of_record)}
    let(:terminated_on)     { TimeKeeper.date_of_record }
    let(:benefit_group_assignment)    { FactoryGirl.build(:benefit_group_assignment) }
    let(:family) { FactoryGirl.build(:family, :with_primary_family_member)}

    let(:hbx_enrollment)    { FactoryGirl.build(:hbx_enrollment, :household => family.active_household, :aasm_state => "coverage_terminated", :terminated_on => TimeKeeper.date_of_record - 1.month) }

    before do
      allow(census_employee).to receive(:active_benefit_group_assignment).and_return(benefit_group_assignment)
      allow(benefit_group_assignment).to receive(:hbx_enrollments).and_return([hbx_enrollment])
    end

    it "should change the terminated_on date" do
      subject.send(:update_enrollments, census_employee, terminated_on)
      expect(census_employee.coverage_terminated_on).to eq(terminated_on)
      expect(hbx_enrollment.terminated_on).to eq(terminated_on)
    end
  end

  describe "census_employee" do
    let(:employer_profile)     { FactoryGirl.create(:employer_profile) }
    let(:census_employee)     { FactoryGirl.create(:census_employee, employer_profile_id: employer_profile.id) }

    it "should return the census employee" do
      found_employee = subject.send(:census_employee, census_employee.ssn, employer_profile.fein)
      expect(found_employee).to eq(census_employee)
    end

    context "census employee not found" do
      it "should return the census employee" do
        expect { subject.send(:census_employee, "000000000", employer_profile.fein) }.to raise_error("Census_employee not found SSN 000000000 Employer FEIN #{employer_profile.fein}")
      end
    end
  end
end
