# frozen_string_literal: true

require 'rails_helper'

require "#{Rails.root}/spec/models/shared_contexts/census_employee.rb"

RSpec.describe CensusEmployee, type: :model, dbclean: :around_each do
  before do
    DatabaseCleaner.clean
  end

  include_context "census employee base data"

  describe "Model instance" do
    context "model Attributes" do
      it {is_expected.to have_field(:benefit_sponsors_employer_profile_id).of_type(BSON::ObjectId)}
      it {is_expected.to have_field(:expected_selection).of_type(String).with_default_value_of("enroll")}
      it {is_expected.to have_field(:hired_on).of_type(Date)}
    end

    context "Associations" do
      it {is_expected.to embed_many(:benefit_group_assignments)}
      it {is_expected.to embed_many(:census_dependents)}
      it {is_expected.to belong_to(:benefit_sponsorship)}
    end

    context "Validations" do
      it {is_expected.to validate_presence_of(:ssn)}
      it {is_expected.to validate_presence_of(:benefit_sponsors_employer_profile_id)}
      it {is_expected.to validate_presence_of(:employer_profile_id)}
    end

    context "index" do
      it {is_expected.to have_index_for(aasm_state: 1)}
      it {is_expected.to have_index_for(encrypted_ssn: 1, dob: 1, aasm_state: 1)}
    end
  end

  describe "Model initialization", dbclean: :after_each do
    context "with no arguments" do
      let(:params) {{}}

      it "should not save" do
        expect(CensusEmployee.create(**params).valid?).to be_falsey
      end
    end

    context "with no employer profile" do
      let(:params) {valid_params.except(:employer_profile, :benefit_sponsorship)}

      it "should fail validation" do
        expect(CensusEmployee.create(**params).errors[:employer_profile_id].any?).to be_truthy
      end
    end

    context "with no ssn" do
      let(:params) {valid_params.except(:ssn)}

      it "should fail validation" do
        expect(CensusEmployee.create(**params).errors[:ssn].any?).to be_truthy
      end
    end

    context "validates expected_selection" do
      let(:params_expected_selection) {valid_params.merge(expected_selection: "enroll")}
      let(:params_in_valid) {valid_params.merge(expected_selection: "rspec-mock")}

      it "should have a valid value" do
        expect(CensusEmployee.create(**params_expected_selection).valid?).to be_truthy
      end

      it "should have a valid value" do
        expect(CensusEmployee.create(**params_in_valid).valid?).to be_falsey
      end
    end

    context "with no dob" do
      let(:params) {valid_params.except(:dob)}

      it "should fail validation" do
        expect(CensusEmployee.create(**params).errors[:dob].any?).to be_truthy
      end
    end

    context "with no hired_on" do
      let(:params) {valid_params.except(:hired_on)}

      it "should fail validation" do
        expect(CensusEmployee.create(**params).errors[:hired_on].any?).to be_truthy
      end
    end

    context "with no is owner" do
      let(:params) {valid_params.merge({:is_business_owner => nil})}

      it "should fail validation" do
        expect(CensusEmployee.create(**params).errors[:is_business_owner].any?).to be_truthy
      end
    end

    context "with all required attributes" do
      let(:params) {valid_params}
      let(:initial_census_employee) {CensusEmployee.new(**params)}

      it "should be valid" do
        expect(initial_census_employee.valid?).to be_truthy
      end

      it "should save" do
        expect(initial_census_employee.save).to be_truthy
      end

      it "should be findable by ID" do
        initial_census_employee.save
        expect(CensusEmployee.find(initial_census_employee.id)).to eq initial_census_employee
      end

      it "in an unlinked state" do
        expect(initial_census_employee.eligible?).to be_truthy
      end

      it "and should have the correct associated employer profile" do
        expect(initial_census_employee.employer_profile._id).to eq initial_census_employee.benefit_sponsors_employer_profile_id
      end

      it "should be findable by employer profile" do
        initial_census_employee.save
        expect(CensusEmployee.find_all_by_employer_profile(employer_profile).size).to eq 1
        expect(CensusEmployee.find_all_by_employer_profile(employer_profile).first).to eq initial_census_employee
      end
    end
  end
end