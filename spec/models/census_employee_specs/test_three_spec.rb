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

  context "validation for employment_terminated_on" do
    let(:census_employee) {FactoryBot.build(:benefit_sponsors_census_employee, employer_profile: employer_profile, benefit_sponsorship: organization.active_benefit_sponsorship, hired_on: TimeKeeper.date_of_record.beginning_of_year - 50.days)}

    it "should fail when terminated date before than hired date" do
      census_employee.employment_terminated_on = census_employee.hired_on - 10.days
      expect(census_employee.valid?).to be_falsey
      expect(census_employee.errors[:employment_terminated_on].any?).to be_truthy
    end

    it "should fail when terminated date not within 60 days" do
      census_employee.employment_terminated_on = TimeKeeper.date_of_record - 75.days
      expect(census_employee.valid?).to be_falsey
      expect(census_employee.errors[:employment_terminated_on].any?).to be_truthy
    end

    it "should success" do
      census_employee.employment_terminated_on = TimeKeeper.date_of_record - 1.day
      expect(census_employee.valid?).to be_truthy
      expect(census_employee.errors[:employment_terminated_on].any?).to be_falsey
    end
  end

  context "validation for census_dependents_relationship" do
    let(:census_employee) {FactoryBot.build(:benefit_sponsors_census_employee, employer_profile: employer_profile, benefit_sponsorship: organization.active_benefit_sponsorship)}
    let(:spouse1) {FactoryBot.build(:census_dependent, employee_relationship: "spouse")}
    let(:spouse2) {FactoryBot.build(:census_dependent, employee_relationship: "spouse")}
    let(:partner1) {FactoryBot.build(:census_dependent, employee_relationship: "domestic_partner")}
    let(:partner2) {FactoryBot.build(:census_dependent, employee_relationship: "domestic_partner")}

    it "should fail when have tow spouse" do
      allow(census_employee).to receive(:census_dependents).and_return([spouse1, spouse2])
      expect(census_employee.valid?).to be_falsey
      expect(census_employee.errors[:census_dependents].any?).to be_truthy
    end

    it "should fail when have tow domestic_partner" do
      allow(census_employee).to receive(:census_dependents).and_return([partner2, partner1])
      expect(census_employee.valid?).to be_falsey
      expect(census_employee.errors[:census_dependents].any?).to be_truthy
    end

    it "should fail when have one spouse and one domestic_partner" do
      allow(census_employee).to receive(:census_dependents).and_return([spouse1, partner1])
      expect(census_employee.valid?).to be_falsey
      expect(census_employee.errors[:census_dependents].any?).to be_truthy
    end

    it "should success when have no dependents" do
      allow(census_employee).to receive(:census_dependents).and_return([])
      expect(census_employee.errors[:census_dependents].any?).to be_falsey
    end

    it "should success" do
      allow(census_employee).to receive(:census_dependents).and_return([partner1])
      expect(census_employee.errors[:census_dependents].any?).to be_falsey
    end
  end

  context "scope employee_name" do
    let(:census_employee1) do
      FactoryBot.create(
        :benefit_sponsors_census_employee,
        benefit_sponsorship: employer_profile.active_benefit_sponsorship,
        employer_profile: employer_profile,
        first_name: "Amy",
        last_name: "Frank"
      )
    end

    let(:census_employee2) do
      FactoryBot.create(
        :benefit_sponsors_census_employee,
        benefit_sponsorship: employer_profile.active_benefit_sponsorship,
        employer_profile: employer_profile,
        first_name: "Javert",
        last_name: "Burton"
      )
    end

    let(:census_employee3) do
      FactoryBot.create(
        :benefit_sponsors_census_employee,
        benefit_sponsorship: employer_profile.active_benefit_sponsorship,
        employer_profile: employer_profile,
        first_name: "Burt",
        last_name: "Love"
      )
    end

    before :each do
      CensusEmployee.delete_all
      census_employee1
      census_employee2
      census_employee3
    end

    it "search by first_name" do
      expect(CensusEmployee.employee_name("Javert")).to eq [census_employee2]
    end

    it "search by last_name" do
      expect(CensusEmployee.employee_name("Frank")).to eq [census_employee1]
    end

    it "search by full_name" do
      expect(CensusEmployee.employee_name("Amy Frank")).to eq [census_employee1]
    end

    it "search by part of name" do
      expect(CensusEmployee.employee_name("Bur").count).to eq 2
      expect(CensusEmployee.employee_name("Bur")).to include census_employee2
      expect(CensusEmployee.employee_name("Bur")).to include census_employee3
    end
  end

  context "update_hbx_enrollment_effective_on_by_hired_on" do

    let(:employee_role) {FactoryBot.create(:benefit_sponsors_employee_role, employer_profile: employer_profile)}
    let(:census_employee) do
      FactoryBot.create(
        :benefit_sponsors_census_employee,
        benefit_sponsorship: employer_profile.active_benefit_sponsorship,
        employer_profile: employer_profile,
        employee_role_id: employee_role.id
      )
    end

    let(:person) {double}
    let(:family) {double(id: '1', active_household: double(hbx_enrollments: double(shop_market: double(enrolled_and_renewing: double(open_enrollments: [@enrollment])))))}

    let(:benefit_group) {double}

    before :each do
      family = FactoryBot.create(:family, :with_primary_family_member)
      @enrollment = FactoryBot.create(:hbx_enrollment, family: family, household: family.active_household)
    end

    it "should update employee_role hired_on" do
      census_employee.update(hired_on: TimeKeeper.date_of_record + 10.days)
      employee_role.reload
      expect(employee_role.hired_on).to eq TimeKeeper.date_of_record + 10.days
    end

    it "should update hbx_enrollment effective_on" do
      allow(census_employee).to receive(:employee_role).and_return(employee_role)
      allow(employee_role).to receive(:person).and_return(person)
      allow(person).to receive(:primary_family).and_return(family)
      allow(@enrollment).to receive(:effective_on).and_return(TimeKeeper.date_of_record - 10.days)
      allow(@enrollment).to receive(:benefit_group).and_return(benefit_group)
      allow(benefit_group).to receive(:effective_on_for).and_return(TimeKeeper.date_of_record + 20.days)
      census_employee.update(hired_on: TimeKeeper.date_of_record + 10.days)
      @enrollment.reload
      expect(@enrollment.read_attribute(:effective_on)).to eq TimeKeeper.date_of_record + 20.days
    end
  end

  context "Employee is migrated into Enroll database without an EmployeeRole" do
    let(:person) {}
    let(:family) {}
    let(:employer_profile) {}
    let(:plan_year) {}
    let(:hbx_enrollment) {}
    let(:benefit_group_assignment) {}

    context "and the employee links to roster" do

      it "should create an employee_role"
    end

    context "and the employee is terminated" do

      it "should create an employee_role"
    end
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