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

  describe "Employee terminated" do
    let(:params) {valid_params}
    let(:initial_census_employee) {CensusEmployee.new(**params)}
    context "and employee is terminated and reported by employer on timely basis" do

      let(:termination_maximum) { Settings.aca.shop_market.retroactive_coverage_termination_maximum.to_hash }
      let(:earliest_retro_coverage_termination_date) {TimeKeeper.date_of_record.advance(termination_maximum).end_of_month }
      let(:earliest_valid_employment_termination_date) {earliest_retro_coverage_termination_date.beginning_of_month}
      let(:invalid_employment_termination_date) {earliest_valid_employment_termination_date - 1.day}
      let(:invalid_coverage_termination_date) {invalid_employment_termination_date.end_of_month}


      context "and the employment termination is reported later after max retroactive date" do

        before {initial_census_employee.terminate_employment!(invalid_employment_termination_date)}

        it "calculated coverage termination date should preceed the valid coverage termination date" do
          expect(invalid_coverage_termination_date).to be < earliest_retro_coverage_termination_date
        end

        it "is in terminated state" do
          expect(CensusEmployee.find(initial_census_employee.id).aasm_state).to eq "employment_terminated"
        end

        it "should have the correct employment termination date" do
          expect(CensusEmployee.find(initial_census_employee.id).employment_terminated_on).to eq invalid_employment_termination_date
        end

        it "should have the earliest coverage termination date" do
          expect(CensusEmployee.find(initial_census_employee.id).coverage_terminated_on).to eq earliest_retro_coverage_termination_date
        end

        context "and the user is HBX admin" do
          it "should use cancancan to permit admin termination"
        end
      end

      context "and the termination date is in the future" do
        before {initial_census_employee.terminate_employment!(TimeKeeper.date_of_record + 10.days)}
        it "is in termination pending state" do
          expect(CensusEmployee.find(initial_census_employee.id).aasm_state).to eq "employee_termination_pending"
        end
      end

      context ".terminate_future_scheduled_census_employees" do
        it "should terminate the census employee on the day of the termination date" do
          initial_census_employee.update_attributes(employment_terminated_on: TimeKeeper.date_of_record + 2.days, aasm_state: "employee_termination_pending")
          CensusEmployee.terminate_future_scheduled_census_employees(TimeKeeper.date_of_record + 2.days)
          expect(CensusEmployee.find(initial_census_employee.id).aasm_state).to eq "employment_terminated"
        end

        it "should not terminate the census employee if today's date < termination date" do
          initial_census_employee.update_attributes(employment_terminated_on: TimeKeeper.date_of_record + 2.days, aasm_state: "employee_termination_pending")
          CensusEmployee.terminate_future_scheduled_census_employees(TimeKeeper.date_of_record + 1.day)
          expect(CensusEmployee.find(initial_census_employee.id).aasm_state).to eq "employee_termination_pending"
        end

        it "should return the existing state of the census employee if today's date > termination date" do
          initial_census_employee.save
          initial_census_employee.update_attributes(employment_terminated_on: TimeKeeper.date_of_record + 2.days, aasm_state: "employment_terminated")
          CensusEmployee.terminate_future_scheduled_census_employees(TimeKeeper.date_of_record + 3.days)
          expect(CensusEmployee.find(initial_census_employee.id).aasm_state).to eq "employment_terminated"
        end

        it "should also terminate the census employees if termination date is in the past" do
          initial_census_employee.update_attributes(employment_terminated_on: TimeKeeper.date_of_record - 3.days, aasm_state: "employee_termination_pending")
          CensusEmployee.terminate_future_scheduled_census_employees(TimeKeeper.date_of_record)
          expect(CensusEmployee.find(initial_census_employee.id).aasm_state).to eq "employment_terminated"
        end
      end

      context "and the termination date is within the retroactive reporting time period" do
        before {initial_census_employee.terminate_employment!(earliest_valid_employment_termination_date)}

        it "is in terminated state" do
          expect(CensusEmployee.find(initial_census_employee.id).aasm_state).to eq "employment_terminated"
        end

        it "should have the correct employment termination date" do
          expect(CensusEmployee.find(initial_census_employee.id).employment_terminated_on).to eq earliest_valid_employment_termination_date
        end

        it "should have the earliest coverage termination date" do
          expect(CensusEmployee.find(initial_census_employee.id).coverage_terminated_on).to eq earliest_retro_coverage_termination_date
        end


        context "and the terminated employee is rehired" do
          let!(:rehire) {initial_census_employee.replicate_for_rehire}

          it "rehired census employee instance should have same demographic info" do
            expect(rehire.first_name).to eq initial_census_employee.first_name
            expect(rehire.last_name).to eq initial_census_employee.last_name
            expect(rehire.gender).to eq initial_census_employee.gender
            expect(rehire.ssn).to eq initial_census_employee.ssn
            expect(rehire.dob).to eq initial_census_employee.dob
            expect(rehire.employer_profile).to eq initial_census_employee.employer_profile
          end

          it "rehired census employee instance should be initialized state" do
            expect(rehire.eligible?).to be_truthy
            expect(rehire.hired_on).to_not eq initial_census_employee.hired_on
            expect(rehire.active_benefit_group_assignment.present?).to be_falsey
            expect(rehire.employee_role.present?).to be_falsey
          end

          it "the previously terminated census employee should be in rehired state" do
            expect(initial_census_employee.aasm_state).to eq "rehired"
          end
        end
      end
    end
  end

  describe "When Employee Role" do
    let(:params) {valid_params}
    let(:initial_census_employee) {CensusEmployee.new(**params)}

    context "and a benefit group isn't yet assigned to employee" do
      it "the roster instance should not be ready for linking" do
        initial_census_employee.benefit_group_assignments.delete_all
        expect(initial_census_employee.may_link_employee_role?).to be_falsey
      end
    end

    context "and a benefit group is assigned to employee" do
      let(:benefit_group_assignment) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: benefit_group, census_employee: initial_census_employee)}

      before do
        initial_census_employee.benefit_group_assignments = [benefit_group_assignment]
        initial_census_employee.save
      end

      it "the employee census record should be ready for linking" do
        expect(initial_census_employee.may_link_employee_role?).to be_truthy
      end
    end

    context "and the benefit group plan year isn't published" do
      it "the roster instance should not be ready for linking" do
        benefit_application.cancel! if benefit_application.may_cancel?
        expect(initial_census_employee.may_link_employee_role?).to be_falsey
      end
    end
  end
end