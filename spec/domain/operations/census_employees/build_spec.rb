# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Operations::CensusEmployees::Build, :type => :model, dbclean: :around_each do

  let(:census_employee)               { FactoryBot.build(:census_employee) }

  let(:valid_params)   {
    {
      first_name: census_employee.first_name,
      middle_name: census_employee.middle_name,
      last_name: census_employee.last_name,
      encrypted_ssn: census_employee.encrypted_ssn,
      gender: census_employee.gender,
      dob: census_employee.dob,
      hired_on: census_employee.hired_on,
      aasm_state: census_employee.aasm_state,
      employee_relationship: census_employee.employee_relationship,
      benefit_sponsors_employer_profile_id: census_employee.benefit_sponsors_employer_profile_id,
      is_business_owner: false,
      benefit_sponsorship_id: census_employee.benefit_sponsorship_id
    }
  }

  let(:missing_params) {valid_params.except(:first_name) }

  let(:invalid_params) {valid_params.merge(hired_on: '1234')}

  context "Invalid params" do
    context "sending with missing parameters should fail validation with errors" do
      it { expect(subject.call(missing_params).failure?).to be_truthy }
      it { expect(subject.call(missing_params).failure.to_h.keys).to eq [:first_name] }
    end

    context "sending with invalid parameters should fail validation with errors" do
      it { expect(subject.call(invalid_params).failure?).to be_truthy }
      it { expect(subject.call(invalid_params).failure.to_h).to eq({:hired_on => ["must be a date"]}) }
    end
  end

  context "with valid params" do
    it "should create new CensusEmployee instance" do
      expect(subject.call(valid_params).success).to be_a Entities::CensusEmployees::CensusEmployee
    end
  end
end
