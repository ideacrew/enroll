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

  context "is_linked?" do

    let(:census_employee) do
      FactoryBot.build(
        :benefit_sponsors_census_employee,
        employer_profile: employer_profile,
        benefit_sponsorship: organization.active_benefit_sponsorship
      )
    end

    it "should return true when aasm_state is employee_role_linked" do
      census_employee.aasm_state = 'employee_role_linked'
      expect(census_employee.is_linked?).to be_truthy
    end

    it "should return true when aasm_state is cobra_linked" do
      census_employee.aasm_state = 'cobra_linked'
      expect(census_employee.is_linked?).to be_truthy
    end

    it "should return false" do
      expect(census_employee.is_linked?).to be_falsey
    end
  end

  context 'past_enrollment' do
    let!(:census_employee) do
      ce = FactoryBot.create(
        :benefit_sponsors_census_employee,
        employer_profile: employer_profile,
        benefit_sponsorship: benefit_sponsorship,
        dob: TimeKeeper.date_of_record - 30.years
      )
      person = FactoryBot.create(:person, last_name: ce.last_name, first_name: ce.first_name)
      employee_role = FactoryBot.build(
        :benefit_sponsors_employee_role,
        person: person,
        census_employee: ce,
        employer_profile: employer_profile
      )
      ce.update_attributes({employee_role: employee_role})
      Family.find_or_build_from_employee_role(employee_role)
      ce
    end

    let!(:enrollment) do
      FactoryBot.create(
        :hbx_enrollment,
        household: census_employee.employee_role.person.primary_family.active_household,
        family: census_employee.employee_role.person.primary_family,
        coverage_kind: "health",
        kind: "employer_sponsored",
        benefit_sponsorship_id: benefit_sponsorship.id,
        sponsored_benefit_package_id: initial_application.benefit_packages.first.id,
        employee_role_id: census_employee.employee_role.id,
        benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id,
        aasm_state: "coverage_terminated"
      )
    end
    let!(:family) { census_employee.employee_role.person.primary_family }

    it "should return enrollments" do
      expect(census_employee.past_enrollments.count).to eq 1
    end

    context 'should not return enrollment' do
      before do
        enrollment.update_attributes(external_enrollment: true)
      end

      it 'returns 0 enrollments' do
        expect(census_employee.past_enrollments.count).to eq(0)
      end
    end
  end
end