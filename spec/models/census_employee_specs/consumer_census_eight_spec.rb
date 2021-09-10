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

  context 'editing a CensusEmployee SSN/DOB that is in a linked status' do

    let(:census_employee) do
      FactoryBot.create :benefit_sponsors_census_employee,
                        employer_profile: employer_profile,
                        benefit_sponsorship: organization.active_benefit_sponsorship
    end

    let(:person) {FactoryBot.create(:person)}

    let(:user) {double("user")}
    let(:employee_role) {FactoryBot.build(:benefit_sponsors_employee_role, employer_profile: organization.employer_profile)}


    it 'should allow Admins to edit a CensusEmployee SSN/DOB that is in a linked status' do
      allow(user).to receive(:has_hbx_staff_role?).and_return true # Admin
      allow(person).to receive(:employee_roles).and_return [employee_role]
      allow(employee_role).to receive(:census_employee).and_return census_employee
      allow(census_employee).to receive(:aasm_state).and_return "employee_role_linked"
      CensusEmployee.update_census_employee_records(person, user)
      expect(census_employee.ssn).to eq person.ssn
      expect(census_employee.dob).to eq person.dob
    end

    it 'should NOT allow Non-Admins to edit a CensusEmployee SSN/DOB that is in a linked status' do
      allow(user).to receive(:has_hbx_staff_role?).and_return false # Non-Admin
      allow(person).to receive(:employee_roles).and_return [employee_role]
      allow(employee_role).to receive(:census_employee).and_return census_employee
      allow(census_employee).to receive(:aasm_state).and_return "employee_role_linked"
      CensusEmployee.update_census_employee_records(person, user)
      expect(census_employee.ssn).not_to eq person.ssn
      expect(census_employee.dob).not_to eq person.dob
    end
  end

  context "check_hired_on_before_dob" do

    let(:census_employee) do
      FactoryBot.build :benefit_sponsors_census_employee,
                       employer_profile: employer_profile,
                       benefit_sponsorship: organization.active_benefit_sponsorship
    end

    it "should fail" do
      census_employee.dob = TimeKeeper.date_of_record - 30.years
      census_employee.hired_on = TimeKeeper.date_of_record - 31.years
      expect(census_employee.save).to be_falsey
      expect(census_employee.errors[:hired_on].any?).to be_truthy
      expect(census_employee.errors[:hired_on].to_s).to match(/date can't be before  date of birth/)
    end
  end

  context "expected to enroll" do

    let!(:valid_waived_employee) do
      FactoryBot.create :benefit_sponsors_census_employee,
                        employer_profile: employer_profile,
                        benefit_sponsorship: organization.active_benefit_sponsorship,
                        expected_selection: 'waive'
    end

    let!(:enrolling_employee) do
      FactoryBot.create :benefit_sponsors_census_employee,
                        employer_profile: employer_profile,
                        benefit_sponsorship: organization.active_benefit_sponsorship,
                        expected_selection: 'enroll'
    end

    let!(:invalid_waive) do
      FactoryBot.create :benefit_sponsors_census_employee,
                        employer_profile: employer_profile,
                        benefit_sponsorship: organization.active_benefit_sponsorship,
                        expected_selection: 'will_not_participate'
    end

    it "returns true for enrolling employees" do
      expect(enrolling_employee.expected_to_enroll?).to be_truthy
    end

    it "returns false for non enrolling employees" do
      expect(valid_waived_employee.expected_to_enroll?).to be_falsey
      expect(invalid_waive.expected_to_enroll?).to be_falsey
    end

    it "counts waived and enrollees when considering group size" do
      expect(valid_waived_employee.expected_to_enroll_or_valid_waive?).to be_truthy
      expect(enrolling_employee.expected_to_enroll_or_valid_waive?).to be_truthy
      expect(invalid_waive.expected_to_enroll_or_valid_waive?).to be_falsey
    end
  end

  context "when active employees opt to waive" do

    let(:census_employee) do
      FactoryBot.create :benefit_sponsors_census_employee,
                        employer_profile: employer_profile,
                        benefit_sponsorship: organization.active_benefit_sponsorship,
                        benefit_group_assignments: [benefit_group_assignment]
    end
    let(:waived_hbx_enrollment_double) { double('WaivedHbxEnrollment', is_coverage_waived?: true, sponsored_benefit_package_id: benefit_group.id) }
    let(:coverage_selected_hbx_enrollment_double) { double('CoveredHbxEnrollment', is_coverage_waived?: false, sponsored_benefit_package_id: benefit_group.id) }

    let(:benefit_group_assignment) {FactoryBot.build(:benefit_sponsors_benefit_group_assignment, benefit_group: benefit_group)}

    it "returns true when employees waive the coverage" do
      allow(benefit_group_assignment).to receive(:hbx_enrollment).and_return(waived_hbx_enrollment_double)
      expect(census_employee.waived?).to be_truthy
    end
    it "returns false for employees who are enrolling" do
      allow(benefit_group_assignment).to receive(:hbx_enrollment).and_return(coverage_selected_hbx_enrollment_double)
      expect(census_employee.waived?).to be_falsey
    end
  end

  context "when active employees has renewal benefit group" do
    let(:census_employee) {CensusEmployee.new(**valid_params)}
    let(:benefit_group_assignment) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: benefit_group, census_employee: census_employee)}
    let(:waived_hbx_enrollment_double) { double('WaivedHbxEnrollment', is_coverage_waived?: true) }
    before do
      benefit_group_assignment.update_attribute(:updated_at, benefit_group_assignment.updated_at + 1.day)
      benefit_group_assignment.plan_year.update_attribute(:aasm_state, "renewing_enrolled")
    end

    it "returns true when employees waive the coverage" do
      expect(census_employee.waived?).to be_falsey
    end
    it "returns false for employees who are enrolling" do
      allow(benefit_group_assignment).to receive(:hbx_enrollment).and_return(waived_hbx_enrollment_double)
      expect(census_employee.waived?).to be_truthy
    end
  end
end