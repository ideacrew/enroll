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
  context "terminating census employee on the roster & actions on existing enrollments", dbclean: :around_each do

    context "change the aasm state & populates terminated on of enrollments" do

      let(:census_employee) do
        FactoryBot.create(
          :benefit_sponsors_census_employee,
          employer_profile: employer_profile,
          benefit_sponsorship: organization.active_benefit_sponsorship
        )
      end

      let(:employee_role) {FactoryBot.create(:benefit_sponsors_employee_role, employer_profile: employer_profile)}
      let(:family) {FactoryBot.create(:family, :with_primary_family_member)}

      let(:hbx_enrollment) {FactoryBot.create(:hbx_enrollment, family: family, sponsored_benefit_package_id: benefit_group.id, household: family.active_household, coverage_kind: 'health', employee_role_id: employee_role.id)}
      let(:hbx_enrollment_two) {FactoryBot.create(:hbx_enrollment, family: family, sponsored_benefit_package_id: benefit_group.id, household: family.active_household, coverage_kind: 'dental', employee_role_id: employee_role.id)}
      let(:hbx_enrollment_three) {FactoryBot.create(:hbx_enrollment, family: family, sponsored_benefit_package_id: benefit_group.id, household: family.active_household, aasm_state: 'renewing_waived', employee_role_id: employee_role.id)}
      let(:assignment) {double("BenefitGroupAssignment", benefit_package: benefit_group)}

      before do
        allow(census_employee).to receive(:active_benefit_group_assignment).and_return(assignment)
        allow(HbxEnrollment).to receive(:find_enrollments_by_benefit_group_assignment).and_return([hbx_enrollment, hbx_enrollment_two, hbx_enrollment_three], [])
        census_employee.update_attributes(employee_role_id: employee_role.id)
      end

      termination_dates = [TimeKeeper.date_of_record - 5.days, TimeKeeper.date_of_record, TimeKeeper.date_of_record + 5.days]
      termination_dates.each do |terminated_on|

        context 'move the enrollment into proper state' do

          before do
            # we do not want to trigger notice
            # takes too much time on processing
            allow_any_instance_of(BenefitSponsors::ModelEvents::HbxEnrollment).to receive(:notify_on_save).and_return(nil)
            census_employee.terminate_employment!(terminated_on)
          end

          it "should move the health enrollment to pending/terminated status" do
            coverage_end = census_employee.earliest_coverage_termination_on(terminated_on)
            if coverage_end < TimeKeeper.date_of_record
              expect(hbx_enrollment.reload.aasm_state).to eq 'coverage_terminated'
            else
              expect(hbx_enrollment.reload.aasm_state).to eq 'coverage_termination_pending'
            end
          end

          it "should set the coverage termination on date on the health enrollment" do
            expect(hbx_enrollment.reload.terminated_on).to eq census_employee.earliest_coverage_termination_on(terminated_on)
          end

          it "should move the dental enrollment to pending/terminated status" do
            coverage_end = census_employee.earliest_coverage_termination_on(terminated_on)
            if coverage_end < TimeKeeper.date_of_record
              expect(hbx_enrollment_two.reload.aasm_state).to eq 'coverage_terminated'
            else
              expect(hbx_enrollment_two.reload.aasm_state).to eq 'coverage_termination_pending'
            end
          end
        end

        context 'move the enrollment aasm state to cancel status' do

          before do
            hbx_enrollment.update_attribute(:effective_on, TimeKeeper.date_of_record.next_month)
            hbx_enrollment_two.update_attribute(:effective_on, TimeKeeper.date_of_record.next_month)
            # we do not want to trigger notice
            # takes too much time on processing
            allow_any_instance_of(BenefitSponsors::ModelEvents::HbxEnrollment).to receive(:notify_on_save).and_return(nil)
            census_employee.terminate_employment!(terminated_on)
          end

          it "should cancel the health enrollment if effective date is in future" do
            if census_employee.coverage_terminated_on < hbx_enrollment.effective_on
              expect(hbx_enrollment.reload.aasm_state).to eq 'coverage_canceled'
            else
              expect(hbx_enrollment.reload.aasm_state).to eq 'coverage_termination_pending'
            end
          end

          it "should set the coverage termination on date on the health enrollment" do
            if census_employee.coverage_terminated_on < hbx_enrollment.effective_on
              expect(hbx_enrollment.reload.terminated_on).to eq nil
            else
              expect(hbx_enrollment.reload.terminated_on).to eq census_employee.coverage_terminated_on
            end
          end

          it "should cancel the dental enrollment if effective date is in future" do
            if census_employee.coverage_terminated_on < hbx_enrollment.effective_on
              expect(hbx_enrollment.reload.aasm_state).to eq 'coverage_canceled'
            else
              expect(hbx_enrollment.reload.aasm_state).to eq 'coverage_termination_pending'
            end
          end

          it "should set the coverage termination on date on the dental enrollment" do
            if census_employee.coverage_terminated_on < hbx_enrollment.effective_on
              expect(hbx_enrollment_two.reload.terminated_on).to eq nil
            else
              expect(hbx_enrollment.reload.terminated_on).to eq census_employee.coverage_terminated_on
            end
          end
        end

        context 'move to enrollment aasm state to inactive state' do

          before do
            # we do not want to trigger notice
            # takes too much time on processing
            allow_any_instance_of(BenefitSponsors::ModelEvents::HbxEnrollment).to receive(:notify_on_save).and_return(nil)
            census_employee.terminate_employment!(terminated_on)
          end

          it "should move the waived enrollment to inactive state" do
            expect(hbx_enrollment_three.reload.aasm_state).to eq 'inactive' if terminated_on >= TimeKeeper.date_of_record
          end

          it "should set the coverage termination on date on the dental enrollment" do
            expect(hbx_enrollment_three.reload.terminated_on).to eq nil
          end
        end
      end
    end
  end
end