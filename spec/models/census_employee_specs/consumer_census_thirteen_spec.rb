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
  describe 'scopes' do
    context ".covered" do
      let(:site)                  { build(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
      let(:benefit_sponsor)        { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile_initial_application, site: site) }
      let(:benefit_sponsorship)    { benefit_sponsor.active_benefit_sponsorship }
      let(:employer_profile)      {  benefit_sponsorship.profile }
      let!(:benefit_package) { benefit_sponsorship.benefit_applications.first.benefit_packages.first}
      let(:census_employee_for_scope_testing)   { FactoryBot.create(:census_employee, employer_profile: employer_profile) }
      let(:household) { FactoryBot.create(:household, family: family)}
      let(:family) { FactoryBot.create(:family, :with_primary_family_member)}
      let!(:benefit_group_assignment) do
        FactoryBot.create(
          :benefit_sponsors_benefit_group_assignment,
          benefit_group: benefit_package,
          census_employee: census_employee_for_scope_testing,
          start_on: benefit_package.start_on,
          end_on: benefit_package.end_on,
          hbx_enrollment_id: enrollment.id
        )
      end
      let!(:enrollment) do
        FactoryBot.create(:hbx_enrollment, household: household, family: family, aasm_state: 'coverage_selected', sponsored_benefit_package_id: benefit_package.id)
      end

      it "should return covered employees" do
        expect(CensusEmployee.covered).to include(census_employee_for_scope_testing)
      end
    end

    context '.eligible_reinstate_for_package' do
      include_context 'setup initial benefit application'

      let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_month - 6.months }
      let(:aasm_state) { :active }
      let!(:census_employee) { create(:census_employee, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile) }
      let(:benefit_package) { initial_application.benefit_packages[0] }
      let(:active_benefit_group_assignment) do
        FactoryBot.create(
          :benefit_sponsors_benefit_group_assignment,
          benefit_group: benefit_package,
          census_employee: census_employee,
          start_on: benefit_package.start_on,
          end_on: benefit_package.end_on
        )
      end

      context 'when census employee active' do
        it "should return active employees" do
          expect(CensusEmployee.eligible_reinstate_for_package(benefit_package, benefit_package.start_on).count).to eq 1
          expect(CensusEmployee.eligible_reinstate_for_package(benefit_package, benefit_package.start_on).first).to eq census_employee
        end
      end

      context 'when census employee terminated' do
        context 'when terminated date falls under coverage date' do
          before do
            census_employee.update_attributes(employment_terminated_on: benefit_package.end_on)
          end

          it "should return employee for covered date" do
            expect(CensusEmployee.eligible_reinstate_for_package(benefit_package, benefit_package.end_on).count).to eq 1
            expect(CensusEmployee.eligible_reinstate_for_package(benefit_package, benefit_package.end_on).first).to eq census_employee
          end
        end

        context 'when terminated date falls outside coverage date' do
          before do
            census_employee.update_attributes(employment_terminated_on: benefit_package.end_on)
          end

          it "should return empty when no employee exists for covered date" do
            expect(CensusEmployee.eligible_reinstate_for_package(benefit_package, benefit_package.end_on.next_day).count).to eq 0
            expect(CensusEmployee.eligible_reinstate_for_package(benefit_package, benefit_package.end_on.next_day).first).to eq nil
          end
        end
      end
    end

    context 'by_benefit_package_and_assignment_on_or_later' do
      include_context "setup employees"
      before do
        date = TimeKeeper.date_of_record.beginning_of_month
        bga = census_employees.first.benefit_group_assignments.first
        bga.assign_attributes(start_on: date + 1.month)
        bga.save(validate: false)
        bga2 = census_employees.second.benefit_group_assignments.first
        bga2.assign_attributes(start_on: date - 1.month)
        bga2.save(validate: false)

        @census_employees = CensusEmployee.by_benefit_package_and_assignment_on_or_later(initial_application.benefit_packages.first, date)
      end

      it "should return more than one" do
        expect(@census_employees.count).to eq 4
      end

      it 'Should include CE' do
        [census_employees.first.id, census_employees[3].id, census_employees[4].id].each do |ce_id|
          expect(@census_employees.pluck(:id)).to include(ce_id)
        end
      end

      it 'should not include CE' do
        [census_employees[1].id].each do |ce_id|
          expect(@census_employees.pluck(:id)).not_to include(ce_id)
        end
      end
    end
  end

  describe 'construct_employee_role', dbclean: :after_each do
    let(:user)  { FactoryBot.create(:user) }
    context 'when employee_role present' do
      let(:employee_role) { FactoryBot.create(:benefit_sponsors_employee_role, employer_profile: employer_profile) }
      let(:census_employee) do
        FactoryBot.create(
          :benefit_sponsors_census_employee,
          employer_profile: employer_profile,
          benefit_sponsorship: organization.active_benefit_sponsorship,
          employee_role_id: employee_role.id
        )
      end
      before do
        person = employee_role.person
        person.user = user
        person.save
        census_employee.construct_employee_role
        census_employee.reload
      end
      it "should return true when link_employee_role!" do
        expect(census_employee.aasm_state).to eq('employee_role_linked')
      end
    end

    context 'when employee_role not present' do
      let(:census_employee) do
        FactoryBot.create(
          :benefit_sponsors_census_employee,
          employer_profile: employer_profile,
          benefit_sponsorship: organization.active_benefit_sponsorship
        )
      end
      before do
        census_employee.construct_employee_role
        census_employee.reload
      end
      it { expect(census_employee.aasm_state).to eq('eligible') }
    end
  end
end