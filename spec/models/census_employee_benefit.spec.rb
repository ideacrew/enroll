# frozen_string_literal: true

require 'rails_helper'

require "#{Rails.root}/spec/models/shared_contexts/census_employee.rb"

RSpec.describe CensusEmployee, type: :model, dbclean: :around_each do
  before do
    DatabaseCleaner.clean
  end

  include_context "census employee base data"

  describe "#assign_prior_plan_benefit_packages", dbclean: :after_each do
    include_context "setup expired, and active benefit applications"

    context 'new hire hired on falls under prior plan year and prior year shop functionality is enabled' do
      let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_year.prev_year }
      let(:hired_on) { expired_benefit_package.start_on + 10.days }
      let(:census_employee) { create(:census_employee, benefit_sponsorship: benefit_sponsorship, benefit_sponsors_employer_profile_id: benefit_sponsorship.profile.id, hired_on:  hired_on) }
      let(:person) { FactoryBot.create(:person) }

      before do
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:prior_plan_year_shop_sep).and_return(true)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:validate_quadrant).and_return true
      end

      it 'on save should create a benefit group assignment' do
        benefit_group_assignment = census_employee.benefit_package_assignment_on(expired_benefit_package.start_on)
        expect(benefit_group_assignment.present?).to eq true
      end
    end

    context 'new hire hired on does not fall under prior plan year and prior year shop functionality is enabled' do
      let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_year.prev_year }
      let(:hired_on) { active_benefit_package.start_on + 10.days }
      let(:census_employee) { create(:census_employee, benefit_sponsorship: benefit_sponsorship, benefit_sponsors_employer_profile_id: benefit_sponsorship.profile.id, hired_on:  hired_on) }
      let(:person) { FactoryBot.create(:person) }

      before do
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:prior_plan_year_shop_sep).and_return(true)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:validate_quadrant).and_return true
      end

      it 'on save should create a benefit group assignment' do
        benefit_group_assignment = census_employee.benefit_package_assignment_on(expired_benefit_package.start_on)
        expect(benefit_group_assignment.benefit_package_id.to_s).not_to eq expired_benefit_package.id.to_s
      end
    end

    context 'prior year shop functionality is disabled' do
      let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_year.prev_year }
      let(:hired_on) { active_benefit_package.start_on + 10.days }
      let(:census_employee) { create(:census_employee, benefit_sponsorship: benefit_sponsorship, benefit_sponsors_employer_profile_id: benefit_sponsorship.profile.id, hired_on:  hired_on) }
      let(:person) { FactoryBot.create(:person) }

      before do
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:prior_plan_year_shop_sep).and_return(false)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:validate_quadrant).and_return true
      end

      it 'on save should create a benefit group assignment' do
        benefit_group_assignment = census_employee.benefit_package_assignment_on(expired_benefit_package.start_on)
        expect(benefit_group_assignment.benefit_package_id.to_s).not_to eq expired_benefit_package.id.to_s
      end
    end
  end

  context '.benefit_group_assignment_by_package' do
    include_context "setup renewal application"

    let(:census_employee) do
      FactoryBot.create(
        :benefit_sponsors_census_employee,
        employer_profile: employer_profile,
        benefit_sponsorship: benefit_sponsorship
      )
    end
    let(:benefit_group_assignment1) do
      FactoryBot.create(
        :benefit_group_assignment,
        benefit_group: renewal_application.benefit_packages.first,
        census_employee: census_employee,
        start_on: renewal_application.benefit_packages.first.start_on,
        end_on: renewal_application.benefit_packages.first.end_on
      )
    end

    before :each do
      census_employee.benefit_group_assignments.destroy_all
    end

    it "should return the first benefit group assignment by benefit package id and active start on date" do
      benefit_group_assignment1
      expect(census_employee.benefit_group_assignment_by_package(benefit_group_assignment1.benefit_package_id, benefit_group_assignment1.start_on)).to eq(benefit_group_assignment1)
    end

    it "should return nil if no benefit group assignments match criteria" do
      expect(
        census_employee.benefit_group_assignment_by_package(benefit_group_assignment1.benefit_package_id, benefit_group_assignment1.start_on + 1.year)
      ).to eq(nil)
    end
  end

  context '.assign_default_benefit_package' do
    include_context "setup renewal application"

    let(:census_employee) do
      FactoryBot.create(
        :benefit_sponsors_census_employee,
        employer_profile: employer_profile,
        benefit_sponsorship: benefit_sponsorship
      )
    end

    let!(:benefit_group_assignment1) do
      FactoryBot.create(
        :benefit_group_assignment,
        benefit_group: renewal_application.benefit_packages.first,
        census_employee: census_employee,
        start_on: renewal_application.benefit_packages.first.start_on,
        end_on: renewal_application.benefit_packages.first.end_on
      )
    end

    it 'should have active benefit group assignment' do
      expect(census_employee.active_benefit_group_assignment.present?).to be_truthy
      expect(census_employee.active_benefit_group_assignment.benefit_package).to eq benefit_sponsorship.active_benefit_application.benefit_packages.first
    end

    it 'should have renewal benefit group assignment' do
      renewal_application.update_attributes(predecessor_id: benefit_application.id)
      benefit_sponsorship.benefit_applications << renewal_application
      expect(census_employee.renewal_benefit_group_assignment.present?).to be_truthy
      expect(census_employee.renewal_benefit_group_assignment.benefit_package).to eq benefit_sponsorship.renewal_benefit_application.benefit_packages.first
    end

    it 'should have most recent renewal benefit group assignment' do
      renewal_application.update_attributes(predecessor_id: benefit_application.id)
      benefit_sponsorship.benefit_applications << renewal_application
      benefit_group_assignment1.update_attributes(created_at: census_employee.benefit_group_assignments.last.created_at + 1.day)
      expect(census_employee.renewal_benefit_group_assignment.created_at).to eq benefit_group_assignment1.created_at
    end
  end

  context '.create_benefit_group_assignment' do

    let(:benefit_application) {initial_application}
    let(:organization) {initial_application.benefit_sponsorship.profile.organization}
    let!(:blue_collar_benefit_group) {FactoryBot.create(:benefit_sponsors_benefit_packages_benefit_package, title: "blue collar benefit group", benefit_application: benefit_application)}
    let!(:employer_profile) {organization.employer_profile}
    let!(:white_collar_benefit_group) {FactoryBot.create(:benefit_sponsors_benefit_packages_benefit_package, benefit_application: benefit_application, title: "white collar benefit group")}
    let!(:census_employee) {CensusEmployee.create(**valid_params)}

    before do
      census_employee.benefit_group_assignments.delete_all
    end

    context 'when benefit groups are switched' do
      let!(:white_collar_benefit_group_assignment) do
        FactoryBot.create(
          :benefit_sponsors_benefit_group_assignment,
          benefit_group: white_collar_benefit_group,
          census_employee: census_employee,
          start_on: white_collar_benefit_group.start_on,
          end_on: white_collar_benefit_group.end_on
        )
      end

      before do
        [white_collar_benefit_group_assignment].each do |bga|
          if bga.census_employee.employee_role_id.nil?
            person = FactoryBot.create(:person, :with_family, first_name: bga.census_employee.first_name, last_name: bga.census_employee.last_name, dob: bga.census_employee.dob, ssn: bga.census_employee.ssn)
            family = person.primary_family
            employee_role = person.employee_roles.build(
              census_employee_id: bga.census_employee.id,
              ssn: person.ssn,
              hired_on: bga.census_employee.hired_on,
              benefit_sponsors_employer_profile_id: bga.census_employee.benefit_sponsors_employer_profile_id
            )
            employee_role.save!
            employee_role = person.employee_roles.last
            bga.census_employee.update_attributes!(employee_role_id: employee_role.id)
          else
            person = bga.census_employee.employee_role.person
            family = person.primary_family
          end
          hbx_enrollment = FactoryBot.create(
            :hbx_enrollment,
            household: family.households.last,
            family: family,
            coverage_kind: "health",
            kind: "employer_sponsored",
            benefit_sponsorship_id: bga.census_employee.benefit_sponsorship.id,
            employee_role_id: bga.census_employee.employee_role_id,
            sponsored_benefit_package_id: bga.benefit_package_id
          )
          bga.update_attributes!(hbx_enrollment_id: hbx_enrollment.id)
        end
      end
      it 'should create benefit_group_assignment' do
        expect(census_employee.benefit_group_assignments.size).to eq 1
        expect(census_employee.active_benefit_group_assignment).to eq white_collar_benefit_group_assignment
        census_employee.create_benefit_group_assignment([blue_collar_benefit_group])
        census_employee.reload
        expect(census_employee.benefit_group_assignments.size).to eq 2
        expect(census_employee.active_benefit_group_assignment(blue_collar_benefit_group.start_on)).not_to eq white_collar_benefit_group_assignment
      end

      it 'should cancel current benefit_group_assignment' do
        census_employee.create_benefit_group_assignment([blue_collar_benefit_group])
        census_employee.reload
        white_collar_benefit_group_assignment.reload
        expect(white_collar_benefit_group_assignment.end_on).to eq white_collar_benefit_group_assignment.start_on
      end

      it 'benefit_group_assignment end on should match benefit package effective period minimum' do
        census_employee.create_benefit_group_assignment([blue_collar_benefit_group])
        census_employee.reload
        white_collar_benefit_group_assignment.reload
        expect(white_collar_benefit_group_assignment.end_on).to eq white_collar_benefit_group.effective_period.min
      end
    end

    context 'when multiple benefit group assignments with benefit group exists' do
      let!(:blue_collar_benefit_group_assignment1) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: blue_collar_benefit_group, census_employee: census_employee, created_at: TimeKeeper.date_of_record - 2.days)}
      let!(:blue_collar_benefit_group_assignment2) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: blue_collar_benefit_group, census_employee: census_employee, created_at: TimeKeeper.date_of_record - 1.day)}
      let!(:blue_collar_benefit_group_assignment3) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: blue_collar_benefit_group, census_employee: census_employee)}
      let!(:white_collar_benefit_group_assignment) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: white_collar_benefit_group, census_employee: census_employee)}

      before do
        expect(census_employee.benefit_group_assignments.size).to eq 4
        [blue_collar_benefit_group_assignment1, blue_collar_benefit_group_assignment2].each do |bga|
          if bga.census_employee.employee_role_id.nil?
            person = FactoryBot.create(:person, :with_family, first_name: bga.census_employee.first_name, last_name: bga.census_employee.last_name, dob: bga.census_employee.dob, ssn: bga.census_employee.ssn)
            family = person.primary_family
            employee_role = person.employee_roles.build(
              census_employee_id: bga.census_employee.id,
              ssn: person.ssn,
              hired_on: bga.census_employee.hired_on,
              benefit_sponsors_employer_profile_id: bga.census_employee.benefit_sponsors_employer_profile_id
            )
            employee_role.save!
            employee_role = person.employee_roles.last
            bga.census_employee.update_attributes!(employee_role_id: employee_role.id)
          else
            person = bga.census_employee.employee_role.person
            family = person.primary_family
          end
          hbx_enrollment = FactoryBot.create(
            :hbx_enrollment,
            household: family.households.last,
            family: family,
            coverage_kind: "health",
            kind: "employer_sponsored",
            benefit_sponsorship_id: bga.census_employee.benefit_sponsorship.id,
            employee_role_id: bga.census_employee.employee_role_id,
            sponsored_benefit_package_id: bga.benefit_package_id
          )
          bga.update_attributes!(hbx_enrollment_id: hbx_enrollment.id)
        end
        blue_collar_benefit_group_assignment1.hbx_enrollment.aasm_state = 'coverage_selected'
        blue_collar_benefit_group_assignment1.save!(:validate => false)
        blue_collar_benefit_group_assignment2.hbx_enrollment.aasm_state = 'coverage_waived'
        blue_collar_benefit_group_assignment2.hbx_enrollment.save!(:validate => false)
      end

      # use case doesn't exist in R4
      # Switching benefit packages will create new BGAs
      # No activatin previous BGA

      # it 'should activate benefit group assignment with valid enrollment status' do
        # expect(census_employee.benefit_group_assignments.size).to eq 4
        # expect(census_employee.active_benefit_group_assignment).to eq white_collar_benefit_group_assignment
        # expect(blue_collar_benefit_group_assignment2.activated_at).to be_nil
        # census_employee.create_benefit_group_assignment([blue_collar_benefit_group])
        # expect(census_employee.benefit_group_assignments.size).to eq 4
        # expect(census_employee.active_benefit_group_assignment(blue_collar_benefit_group.start_on)).to eq blue_collar_benefit_group_assignment2
        # blue_collar_benefit_group_assignment2.reload
        # TODO: Need to figure why this is showing up as nil.
        # expect(blue_collar_benefit_group_assignment2.activated_at).not_to be_nil
      # end
    end

    # Test case is already tested in above scenario
    # context 'when none present with given benefit group' do
    #   let!(:blue_collar_benefit_group_assignment) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: blue_collar_benefit_group, census_employee: census_employee)}
    #   it 'should create new benefit group assignment' do
    #     expect(census_employee.benefit_group_assignments.size).to eq 1
    #     expect(census_employee.active_benefit_group_assignment.benefit_group).to eq blue_collar_benefit_group
    #     census_employee.create_benefit_group_assignment([white_collar_benefit_group])
    #     expect(census_employee.benefit_group_assignments.size).to eq 2
    #     expect(census_employee.active_benefit_group_assignment.benefit_group).to eq white_collar_benefit_group
    #   end
    # end
  end

  context 'future_active_reinstated_benefit_group_assignment' do
    let(:benefit_package)      { initial_application.benefit_packages.first }
    let(:census_employee)      { FactoryBot.create(:census_employee, employer_profile: abc_profile) }
    let(:start_on) { TimeKeeper.date_of_record.next_month.next_month.beginning_of_month + 1.year }
    let(:end_on) { TimeKeeper.date_of_record.next_month.end_of_month + 1.year }
    let(:benefit_group_assignment) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: benefit_package, census_employee: census_employee)}

    before do
      period = initial_application.effective_period.min + 1.year..(initial_application.effective_period.max + 1.year)
      initial_application.update_attributes!(reinstated_id: BSON::ObjectId.new, aasm_state: :active, effective_period: period)
      benefit_group_assignment.update_attributes(start_on: initial_application.effective_period.min)
    end

    it 'should return benefit group assignment which has reinstated benefit package assigned which is future' do
      census_employee.benefit_sponsorship = abc_profile.benefit_sponsorships.first
      census_employee.save
      expect(census_employee.future_active_reinstated_benefit_group_assignment).to eq benefit_group_assignment
    end

    it 'should return reinstated benefit package assigned' do
      census_employee.benefit_sponsorship = abc_profile.benefit_sponsorships.first
      census_employee.save
      expect(census_employee.reinstated_benefit_package).to eq benefit_package
    end

    it 'should not return benefit group assignment if no reinstated PY is present' do
      initial_application.update_attributes!(reinstated_id: nil)
      census_employee.benefit_sponsorship = abc_profile.benefit_sponsorships.first
      census_employee.save
      expect(census_employee.future_active_reinstated_benefit_group_assignment).to eq nil
    end
  end

  context 'assign reinstated benefit group assignment to census employee' do

    let(:benefit_package)      { initial_application.benefit_packages.first }
    let(:census_employee)      { FactoryBot.create(:census_employee, employer_profile: abc_profile) }

    before do
      period = initial_application.effective_period.min + 1.year..(initial_application.effective_period.max + 1.year)
      initial_application.update_attributes!(reinstated_id: BSON::ObjectId.new, aasm_state: :active, effective_period: period)
    end

    it 'should create benefit group assignment for census employee' do
      census_employee.benefit_sponsorship = abc_profile.benefit_sponsorships.first
      census_employee.save
      census_employee.reinstated_benefit_group_assignment = benefit_package.id

      expect(census_employee.benefit_group_assignments.first.start_on).to eq benefit_package.start_on
    end

    it 'should not create benefit group assignment if no reinstated PY is present' do
      initial_application.update_attributes!(reinstated_id: nil)
      census_employee.benefit_sponsorship = abc_profile.benefit_sponsorships.first
      census_employee.save
      census_employee.benefit_group_assignments = []
      census_employee.reinstated_benefit_group_assignment = nil

      expect(census_employee.benefit_group_assignments.present?).to eq false
    end
  end

  context 'reinstated_benefit_group_enrollments' do
    include_context "setup initial benefit application"

    let(:person) { FactoryBot.create(:person) }
    let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
    let(:employee_role) {FactoryBot.create(:benefit_sponsors_employee_role, employer_profile: abc_profile, person: person)}
    let(:benefit_package)      { initial_application.benefit_packages.first }
    let(:census_employee)      { FactoryBot.create(:census_employee, employer_profile: abc_profile, employee_role_id: employee_role.id) }
    let(:start_on) { TimeKeeper.date_of_record.next_month.next_month.beginning_of_month + 1.year }
    let(:end_on) { TimeKeeper.date_of_record.next_month.end_of_month + 1.year }
    let(:benefit_group_assignment) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: benefit_package, census_employee: census_employee)}

    let!(:reinstated_health_enrollment) do
      FactoryBot.create(
        :hbx_enrollment,
        household: family.active_household,
        coverage_kind: "health",
        kind: "employer_sponsored",
        family: census_employee.employee_role.person.primary_family,
        benefit_sponsorship_id: benefit_sponsorship.id,
        sponsored_benefit_package_id: benefit_package.id,
        employee_role_id: census_employee.employee_role.id,
        benefit_group_assignment_id: benefit_group_assignment.id,
        aasm_state: 'coverage_selected'
      )
    end

    before do
      period = initial_application.effective_period.min + 1.year..(initial_application.effective_period.max + 1.year)
      initial_application.update_attributes!(reinstated_id: BSON::ObjectId.new, aasm_state: :active, effective_period: period)
      census_employee.benefit_sponsorship = abc_profile.benefit_sponsorships.first
      census_employee.save
    end


    it "should give enrollments which have future reinstated py assigned" do
      expect(census_employee.reinstated_benefit_group_enrollments[0]).to eq reinstated_health_enrollment
    end

    it 'should return nil if employee role is not assigned to census employee' do
      census_employee.update_attributes(employee_role_id: nil)
      expect(census_employee.reinstated_benefit_group_enrollments).to eq nil
    end

  end

  context "when active employees has renewal benefit group" do
    let(:census_employee) {CensusEmployee.new(**valid_params)}
    let(:benefit_group_assignment) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: benefit_group, census_employee: census_employee)}
    let(:waived_hbx_enrollment_double) { double('WaivedHbxEnrollment', is_coverage_waived?: true) }
    before do
      benefit_group_assignment.update_attribute(:updated_at, benefit_group_assignment.updated_at + 1.day)
      benefit_group_assignment.benefit_application.update_attribute(:aasm_state, "renewing_enrolled")
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

  describe "#benefit_package_for_date", dbclean: :around_each do
    let(:employer_profile) {abc_profile}
    let(:census_employee) do
      FactoryBot.create :benefit_sponsors_census_employee,
                        employer_profile: employer_profile,
                        benefit_sponsorship: benefit_sponsorship
    end

    before do
      census_employee.save
    end

    context "when ER has imported applications" do

      it "should return nil if given effective_on date is in imported benefit application" do
        initial_application.update_attributes(aasm_state: :imported)
        coverage_date = initial_application.end_on - 1.month
        expect(census_employee.reload.benefit_package_for_date(coverage_date)).to eq nil
      end

      it "should return nil if given coverage_date is not between the bga start_on and end_on dates" do
        initial_application.update_attributes(aasm_state: :imported)
        coverage_date = census_employee.benefit_group_assignments.first.start_on - 1.month
        expect(census_employee.benefit_group_assignment_for_date(coverage_date)).to eq nil
      end

      it "should return latest bga for given coverage_date" do
        bga = census_employee.benefit_group_assignments.first
        coverage_date = bga.start_on
        bga1 = bga.dup
        bga.update_attributes(created_at: bga.created_at - 1.day)
        census_employee.benefit_group_assignments << bga1
        expect(census_employee.benefit_group_assignment_for_date(coverage_date)).to eq bga1
      end
    end

    context "when ER has active and renewal benefit applications" do

      include_context "setup renewal application"

      let(:benefit_group_assignment_two) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: renewal_application.benefit_packages.first, census_employee: census_employee)}

      it "should return active benefit_package if given effective_on date is in active benefit application" do
        coverage_date = initial_application.end_on - 1.month
        expect(census_employee.benefit_package_for_date(coverage_date)).to eq renewal_application.benefit_packages.first
      end

      it "should return renewal benefit_package if given effective_on date is in renewal benefit application" do
        benefit_group_assignment_two
        coverage_date = renewal_application.start_on
        expect(census_employee.benefit_package_for_date(coverage_date)).to eq renewal_application.benefit_packages.first
      end
    end

    context "when ER has imported, mid year conversion and renewal benefit applications" do

      let(:myc_application) do
        FactoryBot.build(:benefit_sponsors_benefit_application,
                         :with_benefit_package,
                         benefit_sponsorship: benefit_sponsorship,
                         aasm_state: :active,
                         default_effective_period: ((benefit_application.end_on - 2.months).next_day..benefit_application.end_on),
                         default_open_enrollment_period: ((benefit_application.end_on - 1.year).next_day - 1.month..(benefit_application.end_on - 1.year).next_day - 15.days))
      end

      let(:mid_year_benefit_group_assignment) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: myc_application.benefit_packages.first, census_employee: census_employee)}
      let(:termination_date) {myc_application.start_on.prev_day}

      before do
        benefit_sponsorship.benefit_applications.each do |ba|
          next if ba == myc_application
          updated_dates = benefit_application.effective_period.min.to_date..termination_date.to_date
          ba.update_attributes!(:effective_period => updated_dates)
          ba.terminate_enrollment!
        end
        benefit_sponsorship.benefit_applications << myc_application
        benefit_sponsorship.save
        census_employee.benefit_group_assignments.first.reload
      end

      it "should return mid year benefit_package if given effective_on date is in both imported & mid year benefit application" do
        coverage_date = myc_application.start_on
        mid_year_benefit_group_assignment
        expect(census_employee.benefit_package_for_date(coverage_date)).to eq myc_application.benefit_packages.first
      end
    end
  end

  describe "#assign_benefit_package" do

    let(:current_effective_date) { (TimeKeeper.date_of_record - 2.months).beginning_of_month }
    let(:effective_period)       { current_effective_date..(current_effective_date.next_year.prev_day) }

    context "when previous benefit package assignment not present" do
      let!(:census_employee) do
        ce = create(:census_employee, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile)
        ce.benefit_group_assignments.delete_all
        ce
      end

      context "when benefit package and start_on date passed" do

        it "should create assignments" do
          expect(census_employee.benefit_group_assignments.blank?).to be_truthy
          census_employee.assign_benefit_package(current_benefit_package, current_benefit_package.start_on)
          expect(census_employee.benefit_group_assignments.count).to eq 1
          assignment = census_employee.benefit_group_assignments.first
          expect(assignment.start_on).to eq current_benefit_package.start_on
          expect(assignment.end_on).to eq current_benefit_package.end_on
        end
      end

      context "when benefit package passed and start_on date nil" do

        it "should create assignment with current date as start date" do
          expect(census_employee.benefit_group_assignments.blank?).to be_truthy
          census_employee.assign_benefit_package(current_benefit_package)
          expect(census_employee.benefit_group_assignments.count).to eq 1
          assignment = census_employee.benefit_group_assignments.first
          expect(assignment.start_on).to eq TimeKeeper.date_of_record
          expect(assignment.end_on).to eq current_benefit_package.end_on
        end
      end
    end

    context "when previous benefit package assignment present" do
      let!(:census_employee)     { create(:census_employee, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile) }
      let!(:new_benefit_package) { initial_application.benefit_packages.create({title: 'Second Benefit Package', probation_period_kind: :first_of_month})}

      context "when new benefit package and start_on date passed" do

        it "should create new assignment and cancel existing assignment" do
          expect(census_employee.benefit_group_assignments.present?).to be_truthy
          census_employee.assign_benefit_package(new_benefit_package, new_benefit_package.start_on)
          expect(census_employee.benefit_group_assignments.count).to eq 2

          prev_assignment = census_employee.benefit_group_assignments.first
          expect(prev_assignment.start_on).to eq current_benefit_package.start_on
          expect(prev_assignment.end_on).to eq current_benefit_package.start_on

          new_assignment = census_employee.benefit_group_assignments.last
          expect(new_assignment.start_on).to eq new_benefit_package.start_on
          # We are creating BGAs with start date and end date by default
          expect(new_assignment.end_on).to eq new_benefit_package.end_on
        end
      end

      context "when new benefit package passed and start_on date nil" do

        it "should create new assignment and term existing assignment with an end date" do
          expect(census_employee.benefit_group_assignments.present?).to be_truthy
          census_employee.assign_benefit_package(new_benefit_package)
          expect(census_employee.benefit_group_assignments.count).to eq 2

          prev_assignment = census_employee.benefit_group_assignments.first
          expect(prev_assignment.start_on).to eq current_benefit_package.start_on
          expect(prev_assignment.end_on).to eq TimeKeeper.date_of_record.prev_day

          new_assignment = census_employee.benefit_group_assignments.last
          expect(new_assignment.start_on).to eq TimeKeeper.date_of_record
          # We are creating BGAs with start date and end date by default
          expect(new_assignment.end_on).to eq new_benefit_package.end_on
        end
      end
    end
  end
end
