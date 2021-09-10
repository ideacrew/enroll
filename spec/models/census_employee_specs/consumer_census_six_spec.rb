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

  context "is_cobra_status?" do
    let(:census_employee) {CensusEmployee.new}

    context 'when existing_cobra is true' do
      before :each do
        census_employee.existing_cobra = 'true'
      end

      it "should return true" do
        expect(census_employee.is_cobra_status?).to be_truthy
      end

      it "aasm_state should be cobra_eligible" do
        expect(census_employee.aasm_state).to eq 'cobra_eligible'
      end
    end

    context "when existing_cobra is false" do
      before :each do
        census_employee.existing_cobra = false
      end

      it "should return false when aasm_state not equal cobra" do
        census_employee.aasm_state = 'eligible'
        expect(census_employee.is_cobra_status?).to be_falsey
      end

      it "should return true when aasm_state equal cobra_linked" do
        census_employee.aasm_state = 'cobra_linked'
        expect(census_employee.is_cobra_status?).to be_truthy
      end
    end
  end

  context "existing_cobra" do
    # let(:census_employee) { FactoryBot.create(:census_employee) }
    let(:census_employee) do
      FactoryBot.create(
        :benefit_sponsors_census_employee,
        employer_profile: employer_profile,
        benefit_sponsorship: organization.active_benefit_sponsorship
      )
    end

    it "should return true" do
      CensusEmployee::COBRA_STATES.each do |state|
        census_employee.aasm_state = state
        expect(census_employee.existing_cobra).to be_truthy
      end
    end
  end

  context 'future_active_reinstated_benefit_group_assignment' do
    include_context "setup initial benefit application"

    let(:benefit_package)      { initial_application.benefit_packages.first }
    let(:census_employee)      { FactoryBot.create(:census_employee, employer_profile: abc_profile) }
    let(:start_on) { TimeKeeper.date_of_record.next_month.next_month.beginning_of_month + 1.year }
    let(:end_on) { TimeKeeper.date_of_record.next_month.end_of_month + 1.year }
    let(:benefit_group_assignment) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: benefit_package, census_employee: census_employee)}

    before do
      period = initial_application.effective_period.min + 1.year..(initial_application.effective_period.max + 1.year)
      initial_application.update_attributes!(reinstated_id: BSON::ObjectId.new, aasm_state: :active, effective_period: period)
      benefit_group_assignment.update_attributes(start_on: initial_application.effective_period.min)
    end

    it 'should return benefit group assignment which has reinstated benefit package assigned which is future' do
      census_employee.benefit_sponsorship = abc_profile.benefit_sponsorships.first
      census_employee.save
      expect(census_employee.future_active_reinstated_benefit_group_assignment).to eq benefit_group_assignment
    end

    it 'should return reinstated benefit package assigned' do
      census_employee.benefit_sponsorship = abc_profile.benefit_sponsorships.first
      census_employee.save
      expect(census_employee.reinstated_benefit_package).to eq benefit_package
    end

    it 'should not return benefit group assignment if no reinstated PY is present' do
      initial_application.update_attributes!(reinstated_id: nil)
      census_employee.benefit_sponsorship = abc_profile.benefit_sponsorships.first
      census_employee.save
      expect(census_employee.future_active_reinstated_benefit_group_assignment).to eq nil
    end
  end

  context 'assign reinstated benefit group assignment to census employee' do
    include_context "setup initial benefit application"

    let(:benefit_package)      { initial_application.benefit_packages.first }
    let(:census_employee)      { FactoryBot.create(:census_employee, employer_profile: abc_profile) }

    before do
      period = initial_application.effective_period.min + 1.year..(initial_application.effective_period.max + 1.year)
      initial_application.update_attributes!(reinstated_id: BSON::ObjectId.new, aasm_state: :active, effective_period: period)
    end

    it 'should create benefit group assignment for census employee' do
      census_employee.benefit_sponsorship = abc_profile.benefit_sponsorships.first
      census_employee.save
      census_employee.reinstated_benefit_group_assignment = benefit_package.id

      expect(census_employee.benefit_group_assignments.first.start_on).to eq benefit_package.start_on
    end

    it 'should not create benefit group assignment if no reinstated PY is present' do
      initial_application.update_attributes!(reinstated_id: nil)
      census_employee.benefit_sponsorship = abc_profile.benefit_sponsorships.first
      census_employee.save
      census_employee.benefit_group_assignments = []
      census_employee.reinstated_benefit_group_assignment = nil

      expect(census_employee.benefit_group_assignments.present?).to eq false
    end
  end
end