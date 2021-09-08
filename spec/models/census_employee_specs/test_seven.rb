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

  context '.enrollments_for_display' do
    include_context "setup renewal application"

    let(:census_employee) do
      ce = FactoryBot.create(
        :benefit_sponsors_census_employee,
        employer_profile: employer_profile,
        benefit_sponsorship: benefit_sponsorship,
        dob: TimeKeeper.date_of_record - 30.years
      )
      person = FactoryBot.create(:person, last_name: ce.last_name, first_name: ce.first_name)
      employee_role = FactoryBot.build(:benefit_sponsors_employee_role, person: person, census_employee: ce, employer_profile: employer_profile)
      FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: renewal_application.benefit_packages.first, census_employee: ce)
      ce.update_attributes({employee_role: employee_role})
      Family.find_or_build_from_employee_role(employee_role)
      ce
    end

    let!(:auto_renewing_health_enrollment) do
      FactoryBot.create(
        :hbx_enrollment,
        household: census_employee.employee_role.person.primary_family.active_household,
        coverage_kind: "health",
        family: census_employee.employee_role.person.primary_family,
        kind: "employer_sponsored",
        benefit_sponsorship_id: benefit_sponsorship.id,
        sponsored_benefit_package_id: renewal_application.benefit_packages.first.id,
        employee_role_id: census_employee.employee_role.id,
        benefit_group_assignment_id: census_employee.renewal_benefit_group_assignment.id,
        aasm_state: "auto_renewing"
      )
    end

    let!(:auto_renewing_dental_enrollment) do
      FactoryBot.create(
        :hbx_enrollment,
        household: census_employee.employee_role.person.primary_family.active_household,
        coverage_kind: "dental",
        family: census_employee.employee_role.person.primary_family,
        kind: "employer_sponsored",
        benefit_sponsorship_id: benefit_sponsorship.id,
        sponsored_benefit_package_id: renewal_application.benefit_packages.first.id,
        employee_role_id: census_employee.employee_role.id,
        benefit_group_assignment_id: census_employee.renewal_benefit_group_assignment.id,
        aasm_state: "auto_renewing"
      )
    end

    let(:enrollment) do
      FactoryBot.create(
        :hbx_enrollment,
        household: census_employee.employee_role.person.primary_family.active_household,
        coverage_kind: "health",
        family: census_employee.employee_role.person.primary_family,
        kind: "employer_sponsored",
        benefit_sponsorship_id: benefit_sponsorship.id,
        sponsored_benefit_package_id: census_employee.active_benefit_package.id,
        employee_role_id: census_employee.employee_role.id,
        benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id,
        aasm_state: "coverage_selected"
      )
    end

    shared_examples_for "enrollments for display" do |state, status, result|
      let!(:health_enrollment) do
        FactoryBot.create(
          :hbx_enrollment,
          household: census_employee.employee_role.person.primary_family.active_household,
          coverage_kind: "health",
          kind: "employer_sponsored",
          family: census_employee.employee_role.person.primary_family,
          benefit_sponsorship_id: benefit_sponsorship.id,
          sponsored_benefit_package_id: census_employee.active_benefit_package.id,
          employee_role_id: census_employee.employee_role.id,
          benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id,
          aasm_state: state
        )
      end

      let!(:dental_enrollment) do
        FactoryBot.create(
          :hbx_enrollment,
          household: census_employee.employee_role.person.primary_family.active_household,
          coverage_kind: "dental",
          family: census_employee.employee_role.person.primary_family,
          kind: "employer_sponsored",
          benefit_sponsorship_id: benefit_sponsorship.id,
          sponsored_benefit_package_id: census_employee.active_benefit_package.id,
          employee_role_id: census_employee.employee_role.id,
          benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id,
          aasm_state: state
        )
      end

      it "should #{status}return #{state} health enrollment" do
        expect(census_employee.enrollments_for_display[0].try(:aasm_state) == state).to eq result
      end

      it "should #{status}return #{state} dental enrollment" do
        expect(census_employee.enrollments_for_display[1].try(:aasm_state) == state).to eq result
      end
    end

    it_behaves_like "enrollments for display", "coverage_selected", "", true
    it_behaves_like "enrollments for display", "coverage_enrolled", "", true
    it_behaves_like "enrollments for display", "coverage_termination_pending", "", true
    it_behaves_like "enrollments for display", "coverage_terminated", "not ", false
    it_behaves_like "enrollments for display", "coverage_expired", "not ", false
    it_behaves_like "enrollments for display", "shopping", "not ", false

    context 'when employer has off-cycle benefit application' do
      let(:terminated_on) { TimeKeeper.date_of_record.end_of_month }
      let(:current_effective_date) { terminated_on.next_day }

      include_context 'setup initial benefit application'

      let(:off_cycle_application) do
        initial_application.update_attributes!(aasm_state: :enrollment_open)
        initial_application
      end
      let(:off_cycle_benefit_package) { off_cycle_application.benefit_packages[0] }
      let(:off_cycle_benefit_group_assignment) do
        FactoryBot.create(
          :benefit_sponsors_benefit_group_assignment,
          benefit_group: off_cycle_benefit_package,
          census_employee: census_employee,
          start_on: off_cycle_benefit_package.start_on,
          end_on: off_cycle_benefit_package.end_on
        )
      end

      let!(:off_cycle_health_enrollment) do
        FactoryBot.create(
          :hbx_enrollment,
          household: census_employee.employee_role.person.primary_family.active_household,
          coverage_kind: "health",
          kind: "employer_sponsored",
          family: census_employee.employee_role.person.primary_family,
          benefit_sponsorship_id: benefit_sponsorship.id,
          sponsored_benefit_package_id: off_cycle_benefit_package.id,
          employee_role_id: census_employee.employee_role.id,
          benefit_group_assignment_id: off_cycle_benefit_group_assignment.id,
          aasm_state: 'coverage_selected'
        )
      end

      before do
        updated_dates = predecessor_application.effective_period.min.to_date..terminated_on
        predecessor_application.update_attributes!(:effective_period => updated_dates, :terminated_on => TimeKeeper.date_of_record, termination_kind: 'voluntary', termination_reason: 'voluntary')
        predecessor_application.terminate_enrollment!
        renewal_application.cancel!
      end

      it 'should return off cycle enrollment' do
        expect(census_employee.enrollments_for_display[0]).to eq off_cycle_health_enrollment
      end
    end

    it 'should return auto renewing health enrollment' do
      renewal_application.approve_application! if renewal_application.may_approve_application?
      benefit_sponsorship.benefit_applications << renewal_application
      benefit_sponsorship.save!
      expect(census_employee.enrollments_for_display[0]).to eq auto_renewing_health_enrollment
    end

    it 'should return auto renewing dental enrollment' do
      renewal_application.approve_application! if renewal_application.may_approve_application?
      benefit_sponsorship.benefit_applications << renewal_application
      benefit_sponsorship.save
      expect(census_employee.enrollments_for_display[1]).to eq auto_renewing_dental_enrollment
    end

    it "should return current and renewing coverages" do
      renewal_application.approve_application! if renewal_application.may_approve_application?
      benefit_sponsorship.benefit_applications << renewal_application
      benefit_sponsorship.save
      enrollment
      expect(census_employee.enrollments_for_display).to eq [enrollment, auto_renewing_health_enrollment, auto_renewing_dental_enrollment]
    end

    it 'has renewal_benefit_group_enrollments' do
      renewal_application.approve_application! if renewal_application.may_approve_application?
      benefit_sponsorship.benefit_applications << renewal_application
      benefit_sponsorship.save
      enrollment
      census_employee.reload
      expect(census_employee.renewal_benefit_group_enrollments.first.class).to eq HbxEnrollment
    end
  end

  context '.past_enrollments' do
    include_context "setup renewal application"

    before do
      benefit_application.expire!
    end

    let(:census_employee) do
      ce = FactoryBot.create(
        :benefit_sponsors_census_employee,
        employer_profile: employer_profile,
        benefit_sponsorship: benefit_sponsorship,
        dob: TimeKeeper.date_of_record - 30.years
      )

      person = FactoryBot.create(:person, last_name: ce.last_name, first_name: ce.first_name)
      employee_role = FactoryBot.build(:benefit_sponsors_employee_role, person: person, census_employee: ce, employer_profile: employer_profile)
      FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: renewal_application.benefit_packages.first, census_employee: ce)
      ce.update_attributes({employee_role: employee_role})
      Family.find_or_build_from_employee_role(employee_role)
      ce
    end

    let(:past_benefit_group_assignment) { FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: benefit_application.benefit_packages.first, census_employee: census_employee) }

    let!(:enrollment) do
      FactoryBot.create(
        :hbx_enrollment,
        household: census_employee.employee_role.person.primary_family.active_household,
        coverage_kind: "health",
        kind: "employer_sponsored",
        family: census_employee.employee_role.person.primary_family,
        benefit_sponsorship_id: benefit_sponsorship.id,
        sponsored_benefit_package_id: initial_application.benefit_packages.first.id,
        employee_role_id: census_employee.employee_role.id,
        benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id,
        aasm_state: "coverage_selected"
      )
    end

    let!(:terminated_enrollment) do
      FactoryBot.create(
        :hbx_enrollment,
        household: census_employee.employee_role.person.primary_family.active_household,
        family: census_employee.employee_role.person.primary_family,
        coverage_kind: "health",
        kind: "employer_sponsored",
        benefit_sponsorship_id: benefit_sponsorship.id,
        sponsored_benefit_package_id: initial_application.benefit_packages.first.id,
        employee_role_id: census_employee.employee_role.id,
        terminated_on: TimeKeeper.date_of_record.prev_day,
        benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id,
        aasm_state: "coverage_terminated"
      )
    end

    let!(:past_expired_enrollment) do
      FactoryBot.create(
        :hbx_enrollment,
        household: census_employee.employee_role.person.primary_family.active_household,
        coverage_kind: "health",
        kind: "employer_sponsored",
        family: census_employee.employee_role.person.primary_family,
        benefit_sponsorship_id: benefit_sponsorship.id,
        sponsored_benefit_package_id: initial_application.benefit_packages.first.id,
        employee_role_id: census_employee.employee_role.id,
        benefit_group_assignment_id: past_benefit_group_assignment.id,
        aasm_state: "coverage_expired"
      )
    end

    let!(:canceled_enrollment) do
      FactoryBot.create(
        :hbx_enrollment,
        household: census_employee.employee_role.person.primary_family.active_household,
        coverage_kind: "health",
        family: census_employee.employee_role.person.primary_family,
        kind: "employer_sponsored",
        benefit_sponsorship_id: benefit_sponsorship.id,
        sponsored_benefit_package_id: initial_application.benefit_packages.first.id,
        employee_role_id: census_employee.employee_role.id,
        benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id,
        aasm_state: "coverage_canceled"
      )
    end
    let!(:canceled_enrollment) do
      FactoryBot.create(
        :hbx_enrollment,
        household: census_employee.employee_role.person.primary_family.active_household,
        coverage_kind: "health",
        family: census_employee.employee_role.person.primary_family,
        kind: "employer_sponsored",
        benefit_sponsorship_id: benefit_sponsorship.id,
        sponsored_benefit_package_id: initial_application.benefit_packages.first.id,
        employee_role_id: census_employee.employee_role.id,
        benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id,
        aasm_state: "coverage_canceled"
      )
    end
    let!(:hbx_profile) { FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period) }

    # https://github.com/health-connector/enroll/pull/1666/files
    # original commit removes this from scope
    xit 'should return past expired enrollment' do
      expect(census_employee.past_enrollments.to_a.include?(past_expired_enrollment)).to eq true
    end

    it 'should display terminated enrollment' do
      expect(census_employee.past_enrollments.to_a.include?(terminated_enrollment)).to eq true
    end

    it 'should NOT return current active enrollment' do
      expect(census_employee.past_enrollments.to_a.include?(enrollment)).to eq false
    end

    it 'should NOT return canceled enrollment' do
      expect(census_employee.past_enrollments.to_a.include?(canceled_enrollment)).to eq false
    end
  end
end