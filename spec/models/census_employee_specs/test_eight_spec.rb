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
      expect(census_employee.errors[:hired_on].to_s).to match /date can't be before  date of birth/
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

  context '.renewal_benefit_group_assignment' do
    include_context "setup renewal application"

    let(:renewal_benefit_group) { renewal_application.benefit_packages.first}
    let(:renewal_product_package2) { renewal_application.benefit_sponsor_catalog.product_packages.detect {|package| package.package_kind != renewal_benefit_group.plan_option_kind} }
    let!(:renewal_benefit_group2) { create(:benefit_sponsors_benefit_packages_benefit_package, health_sponsored_benefit: true, product_package: renewal_product_package2, benefit_application: renewal_application, title: 'Benefit Package 2 Renewal')}
    let(:census_employee) {FactoryBot.create(:benefit_sponsors_census_employee, employer_profile: employer_profile, benefit_sponsorship: organization.active_benefit_sponsorship)}
    let!(:benefit_group_assignment_two) { BenefitGroupAssignment.on_date(census_employee, renewal_effective_date) }


    it "should select the latest renewal benefit group assignment" do
      expect(census_employee.renewal_benefit_group_assignment).to eq benefit_group_assignment_two
    end

    context 'when multiple renewal assignments present' do

      context 'and latest assignment has enrollment associated' do
        let(:benefit_group_assignment_three) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: renewal_benefit_group, census_employee: census_employee, end_on: renewal_benefit_group.end_on)}
        let(:enrollment) { double }

        before do
          benefit_group_assignment_two.update!(end_on: benefit_group_assignment_two.start_on)
          allow(benefit_group_assignment_three).to receive(:hbx_enrollment).and_return(enrollment)
        end

        it 'should return assignment with coverage associated' do
          expect(census_employee.renewal_benefit_group_assignment).to eq benefit_group_assignment_three
        end
      end

      context 'and ealier assignment has enrollment associated' do
        let(:benefit_group_assignment_three) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: renewal_benefit_group, census_employee: census_employee)}
        let(:enrollment) { double }

        before do
          allow(benefit_group_assignment_two).to receive(:hbx_enrollment).and_return(enrollment)
        end

        it 'should return assignment with coverage associated' do
          expect(census_employee.renewal_benefit_group_assignment).to eq benefit_group_assignment_two
        end
      end
    end

    context 'when new benefit package is assigned' do

      it 'should cancel the previous benefit group assignment' do
        previous_bga = census_employee.renewal_benefit_group_assignment
        census_employee.renewal_benefit_group_assignment = renewal_benefit_group2.id
        census_employee.save
        census_employee.reload
        expect(previous_bga.canceled?).to be_truthy
      end

      it 'should create new benefit group assignment' do
        previous_bga = census_employee.renewal_benefit_group_assignment
        census_employee.renewal_benefit_group_assignment = renewal_benefit_group2.id
        census_employee.save
        census_employee.reload
        expect(previous_bga.end_on).to eq renewal_benefit_group.effective_period.min
        expect(census_employee.renewal_benefit_group_assignment).not_to eq previous_bga
      end
    end
  end

  context ".is_waived_under?" do
    let(:census_employee) {CensusEmployee.new(**valid_params)}
    let!(:benefit_group_assignment) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: benefit_group, census_employee: census_employee)}

    before do
      family = FactoryBot.create(:family, :with_primary_family_member)
      allow(census_employee).to receive(:family).and_return(family)
      enrollment = FactoryBot.create(
        :hbx_enrollment, family: family,
                         household: family.active_household,
                         benefit_group_assignment: census_employee.benefit_group_assignments.first,
                         sponsored_benefit_package_id: census_employee.benefit_group_assignments.first.benefit_package.id
      )
      allow(benefit_group_assignment).to receive(:hbx_enrollment).and_return(enrollment)
    end

    context "for initial application" do

      it "should return true when employees waive the coverage" do
        benefit_group_assignment.hbx_enrollment.aasm_state = "inactive"
        benefit_group_assignment.hbx_enrollment.save
        expect(census_employee.is_waived_under?(benefit_group_assignment.benefit_application)).to be_truthy
      end

      it "should return false for employees who are enrolling" do
        expect(census_employee.is_waived_under?(benefit_group_assignment.benefit_application)).to be_falsey
      end
    end

    context "when active employeees has renewal benifit group" do

      before do
        benefit_group_assignment.benefit_application.update_attribute(:aasm_state, "renewing_enrolled")
      end

      it "should return false when employees who are enrolling" do
        expect(census_employee.is_waived_under?(benefit_group_assignment.benefit_application)).to be_falsey
      end

      it "should return true for employees waive the coverage" do
        benefit_group_assignment.hbx_enrollment.aasm_state = "renewing_waived"
        benefit_group_assignment.hbx_enrollment.save
        expect(census_employee.is_waived_under?(benefit_group_assignment.benefit_application)).to be_truthy
      end
    end
  end

  context "and congressional newly designated employees are added" do
    let(:employer_profile_congressional) {employer_profile}
    let(:plan_year) {benefit_application}
    let(:benefit_group_assignment) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: benefit_group, census_employee: civil_servant)}
    let(:civil_servant) {FactoryBot.build(:benefit_sponsors_census_employee, employer_profile: employer_profile_congressional, benefit_sponsorship: organization.active_benefit_sponsorship)}
    let(:initial_state) {"eligible"}
    let(:eligible_state) {"newly_designated_eligible"}
    let(:linked_state) {"newly_designated_linked"}
    let(:employee_linked_state) {"employee_role_linked"}

    specify {expect(civil_servant.aasm_state).to eq initial_state}

    it "should transition to newly designated eligible state" do
      expect {civil_servant.newly_designate!}.to change(civil_servant, :aasm_state).to eq eligible_state
    end

    context "and the census employee is associated with an employee role" do
      before do
        civil_servant.benefit_group_assignments = [benefit_group_assignment]
        civil_servant.newly_designate
      end

      it "should transition to newly designated linked state" do
        expect {civil_servant.link_employee_role!}.to change(civil_servant, :aasm_state).to eq linked_state
      end

      context "and the link to employee role is removed" do
        before do
          civil_servant.benefit_group_assignments = [benefit_group_assignment]
          civil_servant.aasm_state = linked_state
          civil_servant.save!
        end

        it "should revert to 'newly designated eligible' state" do
          expect {civil_servant.delink_employee_role!}.to change(civil_servant, :aasm_state).to eq eligible_state
        end
      end
    end

    context "and multiple newly designated employees are present in database" do
      let(:second_civil_servant) {FactoryBot.build(:benefit_sponsors_census_employee, employer_profile: employer_profile_congressional, benefit_sponsorship: organization.active_benefit_sponsorship)}

      before do
        civil_servant.benefit_group_assignments = [benefit_group_assignment]
        civil_servant.newly_designate!

        second_civil_servant.benefit_group_assignments = [benefit_group_assignment]
        second_civil_servant.save!
        second_civil_servant.newly_designate!
        second_civil_servant.link_employee_role!
      end

      it "the scope should find them all" do
        expect(CensusEmployee.newly_designated.size).to eq 2
      end

      it "the scope should find the eligible census employees" do
        expect(CensusEmployee.eligible.size).to eq 1
      end

      it "the scope should find the linked census employees" do
        expect(CensusEmployee.linked.size).to eq 1
      end

      context "and new plan year begins, ending 'newly designated' status" do
        let!(:hbx_profile) {FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period)}
        # before do
        #   benefit_application.update_attributes(aasm_state: :enrollment_closed)
        #   TimeKeeper.set_date_of_record_unprotected!(Date.today.end_of_year)
        #   TimeKeeper.set_date_of_record(Date.today.end_of_year + 1.day)
        # end

        xit "should transition 'newly designated eligible' status to initial state" do
          expect(civil_servant.aasm_state).to eq eligible_state
        end

        xit "should transition 'newly designated linked' status to linked state" do
          expect(second_civil_servant.aasm_state).to eq employee_linked_state
        end
      end

    end


  end
end