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

  context '.new_hire_enrollment_period' do

    let(:census_employee) {CensusEmployee.new(**valid_params)}
    let(:benefit_group_assignment) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: benefit_group, census_employee: census_employee)}

    before do
      census_employee.benefit_group_assignments = [benefit_group_assignment]
      census_employee.save!
      benefit_group.plan_year.update_attributes(:aasm_state => 'published')
    end

    context 'when hired_on date is in the past' do
      it 'should return census employee created date as new hire enrollment period start date' do
        # created_at will have default utc time zone
        time_zone = TimeKeeper.date_according_to_exchange_at(census_employee.created_at).beginning_of_day
        expect(census_employee.new_hire_enrollment_period.min).to eq time_zone
      end
    end

    context 'when hired_on date is in the future' do
      let(:hired_on) {TimeKeeper.date_of_record + 14.days}

      it 'should return hired_on date as new hire enrollment period start date' do
        expect(census_employee.new_hire_enrollment_period.min).to eq census_employee.hired_on
      end
    end

    context 'when earliest effective date is in future more than 30 days from current date' do
      let(:hired_on) {TimeKeeper.date_of_record}

      # it 'should return earliest_eligible_date as new hire enrollment period end date' do
      #   TODO: - Fix Effective On For & Eligible On on benefit package
      #   expected_end_date = (hired_on + 60.days)
      #   expected_end_date = (hired_on + 60.days).end_of_month + 1.day if expected_end_date.day != 1
      #   expect(census_employee.new_hire_enrollment_period.max).to eq (expected_end_date).end_of_day
      # end
    end

    context 'when earliest effective date less than 30 days from current date' do

      it 'should return 30 days from new hire enrollment period start as end date' do
        expect(census_employee.new_hire_enrollment_period.max).to eq (census_employee.new_hire_enrollment_period.min + 30.days).end_of_day
      end
    end
  end

  context '.earliest_eligible_date' do
    let(:hired_on) {TimeKeeper.date_of_record}

    let(:census_employee) {CensusEmployee.new(**valid_params)}
    let(:benefit_group_assignment) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: benefit_group, census_employee: census_employee)}

    before do
      census_employee.benefit_group_assignments = [benefit_group_assignment]
      census_employee.save!
      # benefit_group.plan_year.update_attributes(:aasm_state => 'published')
    end

    # it 'should return earliest effective date' do
      # TODO: - Fix Effective On For & Eligible On on benefit package
      # eligible_date = (hired_on + 60.days)
      # eligible_date = (hired_on + 60.days).end_of_month + 1.day if eligible_date.day != 1
      # expect(census_employee.earliest_eligible_date).to eq eligible_date
    # end
  end

  context 'Validating CensusEmployee Termination Date' do
    let(:census_employee) {CensusEmployee.new(**valid_params)}

    it 'should return true when census employee is not terminated' do
      expect(census_employee.valid?).to be_truthy
    end

    it 'should return false when census employee date is not within 60 days' do
      census_employee.hired_on = TimeKeeper.date_of_record - 120.days
      census_employee.employment_terminated_on = TimeKeeper.date_of_record - 90.days
      expect(census_employee.valid?).to be_falsey
    end

    it 'should return true when census employee is already terminated' do
      census_employee.hired_on = TimeKeeper.date_of_record - 120.days
      census_employee.save! # set initial state
      census_employee.aasm_state = "employment_terminated"
      census_employee.employment_terminated_on = TimeKeeper.date_of_record - 90.days
      expect(census_employee.valid?).to be_truthy
    end
  end

  context '.benefit_group_assignment_by_package' do
    include_context "setup renewal application"

    let(:census_employee) do
      FactoryBot.create(
        :benefit_sponsors_census_employee,
        employer_profile: employer_profile,
        benefit_sponsorship: benefit_sponsorship
      )
    end
    let(:benefit_group_assignment1) do
      FactoryBot.create(
        :benefit_group_assignment,
        benefit_group: renewal_application.benefit_packages.first,
        census_employee: census_employee,
        start_on: renewal_application.benefit_packages.first.start_on,
        end_on: renewal_application.benefit_packages.first.end_on
      )
    end

    before :each do
      census_employee.benefit_group_assignments.destroy_all
    end

    it "should return the first benefit group assignment by benefit package id and active start on date" do
      benefit_group_assignment1
      expect(census_employee.benefit_group_assignment_by_package(benefit_group_assignment1.benefit_package_id, benefit_group_assignment1.start_on)).to eq(benefit_group_assignment1)
    end

    it "should return nil if no benefit group assignments match criteria" do
      expect(
        census_employee.benefit_group_assignment_by_package(benefit_group_assignment1.benefit_package_id, benefit_group_assignment1.start_on + 1.year)
      ).to eq(nil)
    end
  end

  context '.assign_default_benefit_package' do
    include_context "setup renewal application"

    let(:census_employee) do
      FactoryBot.create(
        :benefit_sponsors_census_employee,
        employer_profile: employer_profile,
        benefit_sponsorship: benefit_sponsorship
      )
    end

    let!(:benefit_group_assignment1) do
      FactoryBot.create(
        :benefit_group_assignment,
        benefit_group: renewal_application.benefit_packages.first,
        census_employee: census_employee,
        start_on: renewal_application.benefit_packages.first.start_on,
        end_on: renewal_application.benefit_packages.first.end_on
      )
    end

    it 'should have active benefit group assignment' do
      expect(census_employee.active_benefit_group_assignment.present?).to be_truthy
      expect(census_employee.active_benefit_group_assignment.benefit_package).to eq benefit_sponsorship.active_benefit_application.benefit_packages.first
    end

    it 'should have renewal benefit group assignment' do
      renewal_application.update_attributes(predecessor_id: benefit_application.id)
      benefit_sponsorship.benefit_applications << renewal_application
      expect(census_employee.renewal_benefit_group_assignment.present?).to be_truthy
      expect(census_employee.renewal_benefit_group_assignment.benefit_package).to eq benefit_sponsorship.renewal_benefit_application.benefit_packages.first
    end

    it 'should have most recent renewal benefit group assignment' do
      renewal_application.update_attributes(predecessor_id: benefit_application.id)
      benefit_sponsorship.benefit_applications << renewal_application
      benefit_group_assignment1.update_attributes(created_at: census_employee.benefit_group_assignments.last.created_at + 1.day)
      expect(census_employee.renewal_benefit_group_assignment.created_at).to eq benefit_group_assignment1.created_at
    end
  end
end