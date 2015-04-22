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
    let(:employee_family_id) { double }
    let(:employee_family) { double }

    subject { Forms::EmploymentRelationship.new({ :employee_family_id => employee_family_id }) }

    before(:each) do
      allow(EmployerCensus::EmployeeFamily).to receive(:find).with(employee_family_id).and_return(employee_family)
    end

    it "should have the correct employee_family_data" do
      expect(subject.employee_family_id).to eq employee_family_id
      expect(subject.employee_family).to eq employee_family
    end
  end

  describe "given additional data needed by the employee_role factory" do
    let(:first_name) { double } 
    let(:last_name) { double } 
    let(:middle_name) { double } 
    let(:name_pfx) { double } 
    let(:name_sfx) { double } 
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
