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
  context "a census employee is added in the database" do

    let!(:existing_census_employee) do
      FactoryBot.create(
        :benefit_sponsors_census_employee,
        employer_profile: employer_profile,
        benefit_sponsorship: employer_profile.active_benefit_sponsorship
      )
    end

    let!(:person) do
      Person.create(
        first_name: existing_census_employee.first_name,
        last_name: existing_census_employee.last_name,
        ssn: existing_census_employee.ssn,
        dob: existing_census_employee.dob,
        gender: existing_census_employee.gender
      )
    end
    let!(:user) {create(:user, person: person)}
    let!(:employee_role) do
      EmployeeRole.create(
        person: person,
        hired_on: existing_census_employee.hired_on,
        employer_profile: existing_census_employee.employer_profile
      )
    end

    it "existing record should be findable" do
      expect(CensusEmployee.find(existing_census_employee.id)).to be_truthy
    end

    context "and a new census employee instance, with same ssn same employer profile is built" do
      let!(:duplicate_census_employee) {existing_census_employee.dup}

      it "should have same identifying info" do
        expect(duplicate_census_employee.ssn).to eq existing_census_employee.ssn
        expect(duplicate_census_employee.employer_profile_id).to eq existing_census_employee.employer_profile_id
      end

      context "and existing census employee is in eligible status" do
        it "existing record should be eligible status" do
          expect(CensusEmployee.find(existing_census_employee.id).aasm_state).to eq "eligible"
        end

        it "new instance should fail validation" do
          expect(duplicate_census_employee.valid?).to be_falsey
          expect(duplicate_census_employee.errors[:base].first).to match(/Employee with this identifying information is already active/)
        end

        context "and assign existing census employee to benefit group" do
          let(:benefit_group_assignment) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: benefit_group, census_employee: existing_census_employee)}

          let!(:saved_census_employee) do
            ee = CensusEmployee.find(existing_census_employee.id)
            ee.benefit_group_assignments = [benefit_group_assignment]
            ee.save
            ee
          end

          context "and publish the plan year and associate census employee with employee_role" do
            before do
              saved_census_employee.employee_role = employee_role
              saved_census_employee.save
            end

            it "existing census employee should be employee_role_linked status" do
              expect(CensusEmployee.find(saved_census_employee.id).aasm_state).to eq "employee_role_linked"
            end

            it "new cenesus employee instance should fail validation" do
              expect(duplicate_census_employee.valid?).to be_falsey
              expect(duplicate_census_employee.errors[:base].first).to match(/Employee with this identifying information is already active/)
            end

            context "and existing employee instance is terminated" do
              before do
                saved_census_employee.terminate_employment(TimeKeeper.date_of_record - 1.day)
                saved_census_employee.save
              end

              it "should be in terminated state" do
                expect(saved_census_employee.aasm_state).to eq "employment_terminated"
              end

              it "new instance should save" do
                expect(duplicate_census_employee.save!).to be_truthy
              end
            end

            context "and the roster census employee instance is in any state besides unlinked" do
              let(:employee_role_linked_state) {saved_census_employee.dup}
              let(:employment_terminated_state) {saved_census_employee.dup}
              before do
                employee_role_linked_state.aasm_state = :employee_role_linked
                employment_terminated_state.aasm_state = :employment_terminated
              end

              it "should prevent linking with another employee role" do
                expect(employee_role_linked_state.may_link_employee_role?).to be_falsey
                expect(employment_terminated_state.may_link_employee_role?).to be_falsey
              end
            end
          end
        end

      end
    end
  end
end