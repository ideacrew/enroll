# frozen_string_literal: true

require 'rails_helper'

require "#{Rails.root}/spec/models/shared_contexts/census_employee.rb"

RSpec.describe CensusEmployee, type: :model, dbclean: :around_each do
  before do
    DatabaseCleaner.clean
  end

  include_context "census employee base data"

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

  context "newhire_enrollment_eligible" do
    let(:census_employee) do
      FactoryBot.create(
        :benefit_sponsors_census_employee,
        employer_profile: employer_profile,
        benefit_sponsorship: organization.active_benefit_sponsorship
      )
    end

    let(:benefit_group_assignment) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: benefit_group, census_employee: census_employee)}

    before do
      allow(census_employee).to receive(:active_benefit_group_assignment).and_return benefit_group_assignment
    end

    it "should return true when active_benefit_group_assignment is initialized" do
      allow(benefit_group_assignment).to receive(:initialized?).and_return true
      expect(census_employee.newhire_enrollment_eligible?).to eq true
    end

    it "should return false when active_benefit_group_assignment is not initialized" do
      allow(benefit_group_assignment).to receive(:initialized?).and_return false
      expect(census_employee.newhire_enrollment_eligible?).to eq false
    end
  end

  context '.new_hire_enrollment_period' do

    let(:census_employee) {CensusEmployee.new(**valid_params)}
    let(:benefit_group_assignment) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: benefit_group, census_employee: census_employee)}

    before do
      census_employee.benefit_group_assignments = [benefit_group_assignment]
      census_employee.save!
      benefit_group.plan_year.update_attributes(:aasm_state => 'published')
    end

    context 'when hired_on date is in the past' do
      it 'should return census employee created date as new hire enrollment period start date' do
        # created_at will have default utc time zone
        time_zone = TimeKeeper.date_according_to_exchange_at(census_employee.created_at).beginning_of_day
        expect(census_employee.new_hire_enrollment_period.min).to eq time_zone
      end
    end

    context 'when hired_on date is in the future' do
      let(:hired_on) {TimeKeeper.date_of_record + 14.days}

      it 'should return hired_on date as new hire enrollment period start date' do
        expect(census_employee.new_hire_enrollment_period.min).to eq census_employee.hired_on
      end
    end

    context 'when earliest effective date less than 30 days from current date' do

      it 'should return 30 days from new hire enrollment period start as end date' do
        expect(census_employee.new_hire_enrollment_period.max).to eq (census_employee.new_hire_enrollment_period.min + 30.days).end_of_day
      end
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

  describe "#has_no_hbx_enrollments?" do
    let(:census_employee) do
      FactoryBot.create :census_employee_with_active_assignment,
                        employer_profile: employer_profile,
                        benefit_sponsorship: organization.active_benefit_sponsorship,
                        benefit_group: benefit_group
    end

    it "should return true if no employee role linked" do
      expect(census_employee.send(:has_no_hbx_enrollments?)).to eq true
    end

    it "should return true if employee role present & no enrollment present" do
      allow(census_employee).to receive(:employee_role).and_return double("EmployeeRole")
      allow(census_employee).to receive(:family).and_return double("Family", id: '1')
      expect(census_employee.send(:has_no_hbx_enrollments?)).to eq true
    end

    it "should return true if employee role present & no active enrollment present" do
      allow(census_employee).to receive(:employee_role).and_return double("EmployeeRole")
      allow(census_employee).to receive(:family).and_return double("Family", id: '1')
      allow(census_employee.active_benefit_group_assignment).to receive(:hbx_enrollment).and_return double("HbxEnrollment", aasm_state: "coverage_canceled")
      expect(census_employee.send(:has_no_hbx_enrollments?)).to eq true
    end

    it "should return false if employee role present & active enrollment present" do
      allow(census_employee).to receive(:employee_role).and_return double("EmployeeRole")
      allow(census_employee).to receive(:family).and_return double("Family", id: '1')
      allow(census_employee.active_benefit_group_assignment).to receive(:hbx_enrollment).and_return double("HbxEnrollment", aasm_state: "coverage_selected")
      expect(census_employee.send(:has_no_hbx_enrollments?)).to eq false
    end
  end
end
