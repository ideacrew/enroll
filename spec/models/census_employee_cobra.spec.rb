# frozen_string_literal: true

require 'rails_helper'

require "#{Rails.root}/spec/models/shared_contexts/census_employee.rb"

RSpec.describe CensusEmployee, type: :model, dbclean: :around_each do
  before do
    DatabaseCleaner.clean
  end

  include_context "census employee base data"

  describe "Cobrahire date checkers" do
    let(:params) {valid_params}
    let(:initial_census_employee) {CensusEmployee.new(**params)}
    context "check_cobra_begin_date" do
      it "should not have errors when existing_cobra is false" do
        initial_census_employee.cobra_begin_date = initial_census_employee.hired_on - 5.days
        initial_census_employee.existing_cobra = false
        expect(initial_census_employee.save).to be_truthy
      end

      context "when existing_cobra is true" do
        before do
          initial_census_employee.existing_cobra = 'true'
        end

        it "should not have errors when hired_on earlier than cobra_begin_date" do
          initial_census_employee.cobra_begin_date = initial_census_employee.hired_on + 5.days
          expect(initial_census_employee.save).to be_truthy
        end

        it "should have errors when hired_on later than cobra_begin_date" do
          initial_census_employee.cobra_begin_date = initial_census_employee.hired_on - 5.days
          expect(initial_census_employee.save).to be_falsey
          expect(initial_census_employee.errors[:cobra_begin_date].to_s).to match(/must be after Hire Date/)
        end
      end
    end
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

  describe "#is_cobra_possible" do
    let(:params) { valid_params.merge(:aasm_state => aasm_state) }
    let(:census_employee) { CensusEmployee.new(**params) }

    context "if censue employee is cobra linked" do
      let(:aasm_state) {"cobra_linked"}

      it "should return false" do
        expect(census_employee.is_cobra_possible?).to eq false
      end
    end

    context "if censue employee is cobra linked" do
      let(:aasm_state) {"employee_termination_pending"}

      it "should return false" do
        expect(census_employee.is_cobra_possible?).to eq true
      end
    end

    context "if censue employee is cobra linked" do
      let(:aasm_state) {"employment_terminated"}

      before do
        allow(census_employee).to receive(:employment_terminated_on).and_return TimeKeeper.date_of_record.last_month
      end

      it "should return false" do
        expect(census_employee.is_cobra_possible?).to eq true
      end
    end
  end

end