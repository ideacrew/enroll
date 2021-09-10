# frozen_string_literal: true

require 'rails_helper'

require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe CensusEmployee, type: :model, dbclean: :around_each do

  before do
    DatabaseCleaner.clean
  end

  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup initial benefit application"

  let(:current_effective_date) { TimeKeeper.date_of_record.end_of_month + 1.day + 1.month }

  let!(:employer_profile) {abc_profile}
  let!(:organization) {abc_organization}

  let!(:benefit_application) {initial_application}
  let!(:benefit_package) {benefit_application.benefit_packages.first}
  let!(:benefit_group) {benefit_package}
  let(:effective_period_start_on) {TimeKeeper.date_of_record.end_of_month + 1.day + 1.month}
  let(:effective_period_end_on) {effective_period_start_on + 1.year - 1.day}
  let(:effective_period) {effective_period_start_on..effective_period_end_on}

  let(:first_name) {"Lynyrd"}
  let(:middle_name) {"Rattlesnake"}
  let(:last_name) {"Skynyrd"}
  let(:name_sfx) {"PhD"}
  let(:ssn) {"230987654"}
  let(:dob) {TimeKeeper.date_of_record - 31.years}
  let(:gender) {"male"}
  let(:hired_on) {TimeKeeper.date_of_record - 14.days}
  let(:is_business_owner) {false}
  let(:address) {Address.new(kind: "home", address_1: "221 R St, NW", city: "Washington", state: "DC", zip: "20001")}
  let(:autocomplete) {" lynyrd skynyrd"}

  let(:valid_params) do
    {
      employer_profile: employer_profile,
      first_name: first_name,
      middle_name: middle_name,
      last_name: last_name,
      name_sfx: name_sfx,
      ssn: ssn,
      dob: dob,
      gender: gender,
      hired_on: hired_on,
      is_business_owner: is_business_owner,
      address: address,
      benefit_sponsorship: organization.active_benefit_sponsorship
    }
  end

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

  describe "Censusdependents validators" do
    let(:params) {valid_params}
    let(:initial_census_employee) {CensusEmployee.new(**params)}
    let(:dependent) {CensusDependent.new(first_name: 'David', last_name: 'Henry', ssn: "", employee_relationship: "spouse", dob: TimeKeeper.date_of_record - 30.years, gender: "male")}
    let(:dependent2) {FactoryBot.build(:census_dependent, employee_relationship: "child_under_26", ssn: 333_333_333, dob: TimeKeeper.date_of_record - 30.years, gender: "male")}

    it "allow dependent ssn's to be updated to nil" do
      initial_census_employee.census_dependents = [dependent]
      initial_census_employee.save!
      expect(initial_census_employee.census_dependents.first.ssn).to match(nil)
    end

    it "ignores dependent ssn's if ssn not nil" do
      initial_census_employee.census_dependents = [dependent2]
      initial_census_employee.save!
      expect(initial_census_employee.census_dependents.first.ssn).to match("333333333")
    end

    context "with duplicate ssn's on dependents" do
      let(:child1) {FactoryBot.build(:census_dependent, employee_relationship: "child_under_26", ssn: 333_333_333)}
      let(:child2) {FactoryBot.build(:census_dependent, employee_relationship: "child_under_26", ssn: 333_333_333)}

      it "should have errors" do
        initial_census_employee.census_dependents = [child1, child2]
        expect(initial_census_employee.save).to be_falsey
        expect(initial_census_employee.errors[:base].first).to match(/SSN's must be unique for each dependent and subscriber/)
      end
    end

    context "with duplicate blank ssn's on dependents" do
      let(:child1) {FactoryBot.build(:census_dependent, first_name: 'Jimmy', last_name: 'Stephens', employee_relationship: "child_under_26", ssn: "")}
      let(:child2) {FactoryBot.build(:census_dependent, first_name: 'Ally', last_name: 'Stephens', employee_relationship: "child_under_26", ssn: "")}

      it "should not have errors" do
        initial_census_employee.census_dependents = [child1, child2]
        expect(initial_census_employee.valid?).to be_truthy
      end
    end

    context "with ssn matching subscribers" do
      let(:child1) {FactoryBot.build(:census_dependent, employee_relationship: "child_under_26", ssn: initial_census_employee.ssn)}

      it "should have errors" do
        initial_census_employee.census_dependents = [child1]
        expect(initial_census_employee.save).to be_falsey
        expect(initial_census_employee.errors[:base].first).to match(/SSN's must be unique for each dependent and subscriber/)
      end
    end


    context "and census employee identifying info is edited" do
      before {initial_census_employee.ssn = "606060606"}

      it "should be be valid" do
        expect(initial_census_employee.valid?).to be_truthy
      end
    end
  end
end