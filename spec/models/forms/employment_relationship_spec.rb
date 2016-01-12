require 'rails_helper'

describe Forms::EmploymentRelationship do
  describe "given data needed to populate the view" do
    let(:employer_name) { double }
    let(:hired_on_date) { double }
    let(:eligible_for_coverage_date) { double }

    subject { Forms::EmploymentRelationship.new({
      :employer_name => employer_name,
      :hired_on => hired_on_date,
      :eligible_for_coverage_on => eligible_for_coverage_date
    }) }

    it "should have the correct display data" do
       expect(subject.employer_name).to eq employer_name
       expect(subject.hired_on).to eq hired_on_date
       expect(subject.eligible_for_coverage_on).to eq eligible_for_coverage_date
    end
  end

  describe "given data needed to specify employee family" do
    let(:census_employee_id) { double }
    let(:census_employee) { double }

    subject { Forms::EmploymentRelationship.new({ :census_employee_id => census_employee_id }) }

    before(:each) do
      allow(CensusEmployee).to receive(:find).with(census_employee_id).and_return(census_employee)
    end

    it "should have the correct employee_family_data" do
      expect(subject.census_employee_id).to eq census_employee_id
      expect(subject.census_employee).to eq census_employee
    end
  end

  describe "given additional data needed by the employee_role factory" do
    let(:first_name) { "first" } 
    let(:last_name) { "last" } 
    let(:middle_name) { "middle" } 
    let(:name_pfx) { "pfx" } 
    let(:name_sfx) { "sfx" } 
    let(:gender) { double }

    subject { Forms::EmploymentRelationship.new({
      :first_name => first_name,
      :last_name => last_name,
      :middle_name => middle_name,
      :name_sfx => name_sfx,
      :name_pfx => name_pfx,
      :gender => gender
    }) }

    it "should provide names and gender" do
       expect(subject.first_name).to eq first_name
       expect(subject.last_name).to eq last_name
       expect(subject.middle_name).to eq middle_name
       expect(subject.name_pfx).to eq name_pfx
       expect(subject.name_sfx).to eq name_sfx
       expect(subject.gender).to eq gender
    end
  end
end
