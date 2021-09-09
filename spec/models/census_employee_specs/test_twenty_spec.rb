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
  describe "#is_terminate_possible" do
  let(:params) { valid_params.merge(:aasm_state => aasm_state) }
  let(:census_employee) { CensusEmployee.new(**params) }

  context "if censue employee is cobra linked" do
    let(:aasm_state) {"employment_terminated"}

    it "should return false" do
      expect(census_employee.is_terminate_possible?).to eq true
    end
  end

  context "if censue employee is cobra linked" do
    let(:aasm_state) {"eligible"}

    it "should return false" do
      expect(census_employee.is_terminate_possible?).to eq false
    end
  end

  context "if censue employee is cobra linked" do
    let(:aasm_state) {"cobra_eligible"}

    it "should return false" do
      expect(census_employee.is_terminate_possible?).to eq false
    end
  end

  context "if censue employee is cobra linked" do
    let(:aasm_state) {"cobra_linked"}

    it "should return false" do
      expect(census_employee.is_terminate_possible?).to eq false
    end
  end

  context "if censue employee is newly designatede linked" do
    let(:aasm_state) {"newly_designated_linked"}

    it "should return false" do
      expect(census_employee.is_terminate_possible?).to eq false
    end
  end
end

describe "#terminate_employee_enrollments", dbclean: :around_each do
  let(:aasm_state) { :imported }
  include_context "setup renewal application"

  let(:renewal_effective_date) { TimeKeeper.date_of_record.beginning_of_month - 2.months }
  let(:predecessor_state) { :expired }
  let(:renewal_state) { :active }
  let(:renewal_benefit_group) { renewal_application.benefit_packages.first}
  let(:census_employee) do
    ce = FactoryBot.create(
        :benefit_sponsors_census_employee,
        employer_profile: employer_profile,
        benefit_sponsorship: organization.active_benefit_sponsorship
    )
    person = FactoryBot.create(:person, last_name: ce.last_name, first_name: ce.first_name)
    employee_role = FactoryBot.build(:benefit_sponsors_employee_role, person: person, census_employee: ce, employer_profile: employer_profile)
    ce.update_attributes({employee_role: employee_role})
    Family.find_or_build_from_employee_role(employee_role)
    ce
  end

  let!(:active_bga) { FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: renewal_benefit_group, census_employee: census_employee) }
  let!(:inactive_bga) { FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: current_benefit_package, census_employee: census_employee) }

  let!(:active_enrollment) do
    FactoryBot.create(
        :hbx_enrollment,
        household: census_employee.employee_role.person.primary_family.active_household,
        coverage_kind: "health",
        kind: "employer_sponsored",
        effective_on: renewal_benefit_group.start_on,
        family: census_employee.employee_role.person.primary_family,
        benefit_sponsorship_id: benefit_sponsorship.id,
        sponsored_benefit_package_id: renewal_benefit_group.id,
        employee_role_id: census_employee.employee_role.id,
        benefit_group_assignment_id: active_bga.id,
        aasm_state: "coverage_selected"
    )
  end

  let!(:expired_enrollment) do
    FactoryBot.create(
        :hbx_enrollment,
        household: census_employee.employee_role.person.primary_family.active_household,
        coverage_kind: "health",
        kind: "employer_sponsored",
        effective_on: current_benefit_package.start_on,
        family: census_employee.employee_role.person.primary_family,
        benefit_sponsorship_id: benefit_sponsorship.id,
        sponsored_benefit_package_id: current_benefit_package.id,
        employee_role_id: census_employee.employee_role.id,
        benefit_group_assignment_id: inactive_bga.id,
        aasm_state: "coverage_expired"
    )
  end

  context "when EE termination date falls under expired application" do
    let!(:date) { benefit_sponsorship.benefit_applications.expired.first.effective_period.max }
    before do
      employment_terminated_on = (TimeKeeper.date_of_record - 3.months).end_of_month
      census_employee.employment_terminated_on = employment_terminated_on
      census_employee.coverage_terminated_on = employment_terminated_on
      census_employee.aasm_state = "employment_terminated"
      # census_employee.benefit_group_assignments.where(is_active: false).first.end_on = date
      census_employee.save
      census_employee.terminate_employee_enrollments(employment_terminated_on)
      expired_enrollment.reload
      active_enrollment.reload
    end

    it "should terminate, expired enrollment with terminated date = ee coverage termination date" do
      expect(expired_enrollment.aasm_state).to eq "coverage_terminated"
      expect(expired_enrollment.terminated_on).to eq date
    end

    it "should cancel active coverage" do
      expect(active_enrollment.aasm_state).to eq "coverage_canceled"
    end
  end

  context "when EE termination date falls under active application" do
    let(:employment_terminated_on) { TimeKeeper.date_of_record.end_of_month }

    before do
      census_employee.employment_terminated_on = employment_terminated_on
      census_employee.coverage_terminated_on = TimeKeeper.date_of_record.end_of_month
      census_employee.aasm_state = "employment_terminated"
      census_employee.save
      census_employee.terminate_employee_enrollments(employment_terminated_on)
      expired_enrollment.reload
      active_enrollment.reload
    end

    it "shouldn't update expired enrollment" do
      expect(expired_enrollment.aasm_state).to eq "coverage_expired"
    end

    it "should termiante active coverage" do
      expect(active_enrollment.aasm_state).to eq "coverage_termination_pending"
    end

    it "should cancel future active coverage" do
      active_enrollment.effective_on = TimeKeeper.date_of_record.next_month
      active_enrollment.save
      census_employee.terminate_employee_enrollments(employment_terminated_on)
      active_enrollment.reload
      expect(active_enrollment.aasm_state).to eq "coverage_canceled"
    end
  end

  context 'when renewal and active benefit group assignments exists' do
    include_context "setup renewal application"

    let(:renewal_benefit_group) { renewal_application.benefit_packages.first}
    let(:renewal_product_package2) { renewal_application.benefit_sponsor_catalog.product_packages.detect {|package| package.package_kind != renewal_benefit_group.plan_option_kind} }
    let!(:renewal_benefit_group2) { create(:benefit_sponsors_benefit_packages_benefit_package, health_sponsored_benefit: true, product_package: renewal_product_package2, benefit_application: renewal_application, title: 'Benefit Package 2 Renewal')}
    let!(:benefit_group_assignment_two) { BenefitGroupAssignment.on_date(census_employee, renewal_effective_date) }
    let!(:renewal_enrollment) do
      FactoryBot.create(
        :hbx_enrollment,
        household: census_employee.employee_role.person.primary_family.active_household,
        coverage_kind: "health",
        kind: "employer_sponsored",
        effective_on: renewal_benefit_group2.start_on,
        family: census_employee.employee_role.person.primary_family,
        benefit_sponsorship_id: benefit_sponsorship.id,
        sponsored_benefit_package_id: renewal_benefit_group2.id,
        employee_role_id: census_employee.employee_role.id,
        benefit_group_assignment_id: census_employee.renewal_benefit_group_assignment.id,
        aasm_state: "auto_renewing"
      )
    end

    before do
      active_enrollment.effective_on = renewal_enrollment.effective_on.prev_year
      active_enrollment.save
      employment_terminated_on = (TimeKeeper.date_of_record - 1.months).end_of_month
      census_employee.employment_terminated_on = employment_terminated_on
      census_employee.coverage_terminated_on = employment_terminated_on
      census_employee.aasm_state = "employment_terminated"
      census_employee.save
      census_employee.terminate_employee_enrollments(employment_terminated_on)
    end

    it "should terminate active enrollment" do
      active_enrollment.reload
      expect(active_enrollment.aasm_state).to eq "coverage_terminated"
    end

    it "should cancel renewal enrollment" do
      renewal_enrollment.reload
      expect(renewal_enrollment.aasm_state).to eq "coverage_canceled"
    end
  end
end
end