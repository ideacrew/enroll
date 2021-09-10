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
  describe "#is_rehired_possible" do
    let(:params) { valid_params.merge(:aasm_state => aasm_state) }
    let(:census_employee) { CensusEmployee.new(**params) }

    context "if censue employee is cobra linked" do
      let(:aasm_state) {"cobra_eligible"}

      it "should return false" do
        expect(census_employee.is_rehired_possible?).to eq false
      end
    end

    context "if censue employee is cobra linked" do
      let(:aasm_state) {"rehired"}

      it "should return false" do
        expect(census_employee.is_rehired_possible?).to eq false
      end
    end

    context "if censue employee is cobra linked" do
      let(:aasm_state) {"cobra_terminated"}

      it "should return false" do
        expect(census_employee.is_rehired_possible?).to eq true
      end
    end
  end

  describe "#assign_benefit_package" do

    let(:current_effective_date) { (TimeKeeper.date_of_record - 2.months).beginning_of_month }
    let(:effective_period)       { current_effective_date..(current_effective_date.next_year.prev_day) }

    context "when previous benefit package assignment not present" do
      let!(:census_employee) do
        ce = create(:census_employee, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile)
        ce.benefit_group_assignments.delete_all
        ce
      end

      context "when benefit package and start_on date passed" do

        it "should create assignments" do
          expect(census_employee.benefit_group_assignments.blank?).to be_truthy
          census_employee.assign_benefit_package(current_benefit_package, current_benefit_package.start_on)
          expect(census_employee.benefit_group_assignments.count).to eq 1
          assignment = census_employee.benefit_group_assignments.first
          expect(assignment.start_on).to eq current_benefit_package.start_on
          expect(assignment.end_on).to eq current_benefit_package.end_on
        end
      end

      context "when benefit package passed and start_on date nil" do

        it "should create assignment with current date as start date" do
          expect(census_employee.benefit_group_assignments.blank?).to be_truthy
          census_employee.assign_benefit_package(current_benefit_package)
          expect(census_employee.benefit_group_assignments.count).to eq 1
          assignment = census_employee.benefit_group_assignments.first
          expect(assignment.start_on).to eq TimeKeeper.date_of_record
          expect(assignment.end_on).to eq current_benefit_package.end_on
        end
      end
    end

    context "when previous benefit package assignment present" do
      let!(:census_employee)     { create(:census_employee, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile) }
      let!(:new_benefit_package) { initial_application.benefit_packages.create({title: 'Second Benefit Package', probation_period_kind: :first_of_month})}

      context "when new benefit package and start_on date passed" do

        it "should create new assignment and cancel existing assignment" do
          expect(census_employee.benefit_group_assignments.present?).to be_truthy
          census_employee.assign_benefit_package(new_benefit_package, new_benefit_package.start_on)
          expect(census_employee.benefit_group_assignments.count).to eq 2

          prev_assignment = census_employee.benefit_group_assignments.first
          expect(prev_assignment.start_on).to eq current_benefit_package.start_on
          expect(prev_assignment.end_on).to eq current_benefit_package.start_on

          new_assignment = census_employee.benefit_group_assignments.last
          expect(new_assignment.start_on).to eq new_benefit_package.start_on
          # We are creating BGAs with start date and end date by default
          expect(new_assignment.end_on).to eq new_benefit_package.end_on
        end
      end

      context "when new benefit package passed and start_on date nil" do

        it "should create new assignment and term existing assignment with an end date" do
          expect(census_employee.benefit_group_assignments.present?).to be_truthy
          census_employee.assign_benefit_package(new_benefit_package)
          expect(census_employee.benefit_group_assignments.count).to eq 2

          prev_assignment = census_employee.benefit_group_assignments.first
          expect(prev_assignment.start_on).to eq current_benefit_package.start_on
          expect(prev_assignment.end_on).to eq TimeKeeper.date_of_record.prev_day

          new_assignment = census_employee.benefit_group_assignments.last
          expect(new_assignment.start_on).to eq TimeKeeper.date_of_record
          # We are creating BGAs with start date and end date by default
          expect(new_assignment.end_on).to eq new_benefit_package.end_on
        end
      end
    end
  end
end