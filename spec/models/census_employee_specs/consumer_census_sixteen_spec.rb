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
  context 'reinstated_benefit_group_enrollments' do
    include_context "setup initial benefit application"

    let(:person) { FactoryBot.create(:person) }
    let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
    let(:employee_role) {FactoryBot.create(:benefit_sponsors_employee_role, employer_profile: abc_profile, person: person)}
    let(:benefit_package)      { initial_application.benefit_packages.first }
    let(:census_employee)      { FactoryBot.create(:census_employee, employer_profile: abc_profile, employee_role_id: employee_role.id) }
    let(:start_on) { TimeKeeper.date_of_record.next_month.next_month.beginning_of_month + 1.year }
    let(:end_on) { TimeKeeper.date_of_record.next_month.end_of_month + 1.year }
    let(:benefit_group_assignment) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: benefit_package, census_employee: census_employee)}

    let!(:reinstated_health_enrollment) do
      FactoryBot.create(
        :hbx_enrollment,
        household: family.active_household,
        coverage_kind: "health",
        kind: "employer_sponsored",
        family: census_employee.employee_role.person.primary_family,
        benefit_sponsorship_id: benefit_sponsorship.id,
        sponsored_benefit_package_id: benefit_package.id,
        employee_role_id: census_employee.employee_role.id,
        benefit_group_assignment_id: benefit_group_assignment.id,
        aasm_state: 'coverage_selected'
      )
    end

    before do
      period = initial_application.effective_period.min + 1.year..(initial_application.effective_period.max + 1.year)
      initial_application.update_attributes!(reinstated_id: BSON::ObjectId.new, aasm_state: :active, effective_period: period)
      census_employee.benefit_sponsorship = abc_profile.benefit_sponsorships.first
      census_employee.save
    end


    it "should give enrollments which have future reinstated py assigned" do
      expect(census_employee.reinstated_benefit_group_enrollments[0]).to eq reinstated_health_enrollment
    end

    it 'should return nil if employee role is not assigned to census employee' do
      census_employee.update_attributes(employee_role_id: nil)
      expect(census_employee.reinstated_benefit_group_enrollments).to eq nil
    end

  end

  context "have_valid_date_for_cobra with current_user" do
    let(:census_employee100) { FactoryBot.create(:census_employee) }
    let(:person100) { FactoryBot.create(:person, :with_hbx_staff_role) }
    let(:user100) { FactoryBot.create(:user, person: person100) }

    it "should return false even if current_user is a valid admin" do
      expect(census_employee100.have_valid_date_for_cobra?(user100)).to eq false
    end

    it "should return false as census_employee doesn't meet the requirements" do
      expect(census_employee100.have_valid_date_for_cobra?).to eq false
    end
  end

  context "have_valid_date_for_cobra?" do
    let(:hired_on) {TimeKeeper.date_of_record}
    let(:census_employee) do
      FactoryBot.create(
        :benefit_sponsors_census_employee,
        employer_profile: employer_profile,
        benefit_sponsorship: organization.active_benefit_sponsorship,
        hired_on: hired_on
      )
    end

    before :each do
      census_employee.terminate_employee_role!
    end

    it "can cobra employee_role" do
      census_employee.cobra_begin_date = hired_on + 10.days
      census_employee.coverage_terminated_on = TimeKeeper.date_of_record - Settings.aca.shop_market.cobra_enrollment_period.months.months + 5.days
      census_employee.cobra_begin_date = TimeKeeper.date_of_record
      expect(census_employee.may_elect_cobra?).to be_truthy
    end

    it "can not cobra employee_role" do
      census_employee.cobra_begin_date = hired_on + 10.days
      census_employee.coverage_terminated_on = TimeKeeper.date_of_record - Settings.aca.shop_market.cobra_enrollment_period.months.months - 5.days
      census_employee.cobra_begin_date = TimeKeeper.date_of_record
      expect(census_employee.may_elect_cobra?).to be_falsey
    end

    context "current date is less then 6 months after coverage_terminated_on" do
      before :each do
        census_employee.cobra_begin_date = hired_on + 10.days
        census_employee.coverage_terminated_on = TimeKeeper.date_of_record - Settings.aca.shop_market.cobra_enrollment_period.months.months + 5.days
      end

      it "when cobra_begin_date is early than coverage_terminated_on" do
        census_employee.cobra_begin_date = census_employee.coverage_terminated_on - 5.days
        expect(census_employee.may_elect_cobra?).to be_falsey
      end

      it "when cobra_begin_date is later than 6 months after coverage_terminated_on" do
        census_employee.cobra_begin_date = census_employee.coverage_terminated_on + Settings.aca.shop_market.cobra_enrollment_period.months.months + 5.days
        expect(census_employee.may_elect_cobra?).to be_falsey
      end
    end

    it "can not cobra employee_role" do
      census_employee.cobra_begin_date = hired_on - 10.days
      expect(census_employee.may_elect_cobra?).to be_falsey
    end

    it "can not cobra employee_role without cobra_begin_date" do
      census_employee.cobra_begin_date = nil
      expect(census_employee.may_elect_cobra?).to be_falsey
    end
  end

  context "can_elect_cobra?" do
    let(:census_employee) do
      FactoryBot.create(
        :benefit_sponsors_census_employee,
        employer_profile: employer_profile,
        benefit_sponsorship: organization.active_benefit_sponsorship,
        hired_on: hired_on
      )
    end

    it "should return false when aasm_state is eligible" do
      expect(census_employee.can_elect_cobra?).to be_falsey
    end

    it "should return true when aasm_state is employment_terminated" do
      census_employee.aasm_state = 'employment_terminated'
      expect(census_employee.can_elect_cobra?).to be_truthy
    end

    it "should return true when aasm_state is cobra_terminated" do
      census_employee.aasm_state = 'cobra_terminated'
      expect(census_employee.can_elect_cobra?).to be_falsey
    end
  end

  context "show_plan_end_date?" do
    context "without coverage_terminated_on" do

      let(:census_employee) do
        FactoryBot.build(
          :benefit_sponsors_census_employee,
          employer_profile: employer_profile,
          benefit_sponsorship: organization.active_benefit_sponsorship,
          hired_on: hired_on
        )
      end

      (CensusEmployee::EMPLOYMENT_TERMINATED_STATES + CensusEmployee::COBRA_STATES).uniq.each do |state|
        it "should return false when aasm_state is #{state}" do
          census_employee.aasm_state = state
          expect(census_employee.show_plan_end_date?).to be_falsey
        end
      end
    end

    context "with coverage_terminated_on" do

      let(:census_employee) do
        FactoryBot.create(
          :benefit_sponsors_census_employee,
          employer_profile: employer_profile,
          benefit_sponsorship: organization.active_benefit_sponsorship,
          coverage_terminated_on: TimeKeeper.date_of_record
        )
      end

      CensusEmployee::EMPLOYMENT_TERMINATED_STATES.each do |state|
        it "should return false when aasm_state is #{state}" do
          census_employee.aasm_state = state
          expect(census_employee.show_plan_end_date?).to be_truthy
        end
      end

      (CensusEmployee::COBRA_STATES - CensusEmployee::EMPLOYMENT_TERMINATED_STATES).each do |state|
        it "should return false when aasm_state is #{state}" do
          census_employee.aasm_state = state
          expect(census_employee.show_plan_end_date?).to be_falsey
        end
      end
    end
  end

  context "is_cobra_coverage_eligible?" do

    let(:census_employee) do
      FactoryBot.build(
        :benefit_sponsors_census_employee,
        employer_profile: employer_profile,
        benefit_sponsorship: organization.active_benefit_sponsorship
      )
    end

    let(:hbx_enrollment) do
      HbxEnrollment.new(
        aasm_state: "coverage_terminated",
        terminated_on: TimeKeeper.date_of_record,
        coverage_kind: 'health'
      )
    end

    it "should return true when employement is terminated and " do
      allow(Family).to receive(:where).and_return([hbx_enrollment])
      allow(census_employee).to receive(:employment_terminated_on).and_return(TimeKeeper.date_of_record)
      allow(census_employee).to receive(:employment_terminated?).and_return(true)
      expect(census_employee.is_cobra_coverage_eligible?).to be_truthy
    end

    it "should return false when employement is not terminated" do
      allow(census_employee).to receive(:employment_terminated?).and_return(false)
      expect(census_employee.is_cobra_coverage_eligible?).to be_falsey
    end
  end

  context "cobra_eligibility_expired?" do

    let(:census_employee) do
      FactoryBot.build(
        :benefit_sponsors_census_employee,
        employer_profile: employer_profile,
        benefit_sponsorship: organization.active_benefit_sponsorship
      )
    end

    it "should return true when coverage is terminated more that 6 months " do
      allow(census_employee).to receive(:coverage_terminated_on).and_return(TimeKeeper.date_of_record - 7.months)
      expect(census_employee.cobra_eligibility_expired?).to be_truthy
    end

    it "should return false when coverage is terminated not more that 6 months " do
      allow(census_employee).to receive(:coverage_terminated_on).and_return(TimeKeeper.date_of_record - 2.months)
      expect(census_employee.cobra_eligibility_expired?).to be_falsey
    end

    it "should return true when employment terminated more that 6 months " do
      allow(census_employee).to receive(:coverage_terminated_on).and_return(nil)
      allow(census_employee).to receive(:employment_terminated_on).and_return(TimeKeeper.date_of_record - 7.months)
      expect(census_employee.cobra_eligibility_expired?).to be_truthy
    end

    it "should return false when employment terminated not more that 6 months " do
      allow(census_employee).to receive(:coverage_terminated_on).and_return(nil)
      allow(census_employee).to receive(:employment_terminated_on).and_return(TimeKeeper.date_of_record - 1.month)
      expect(census_employee.cobra_eligibility_expired?).to be_falsey
    end
  end
end