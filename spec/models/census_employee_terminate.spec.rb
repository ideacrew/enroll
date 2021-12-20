# frozen_string_literal: true

require 'rails_helper'

require "#{Rails.root}/spec/models/shared_contexts/census_employee.rb"

RSpec.describe CensusEmployee, type: :model, dbclean: :around_each do
  before do
    DatabaseCleaner.clean
  end

  include_context "census employee base data"

  describe "Employee terminated" do
    let(:params) {valid_params}
    let(:initial_census_employee) {CensusEmployee.new(**params)}
    context "and employee is terminated and reported by employer on timely basis" do

      let(:termination_maximum) { Settings.aca.shop_market.retroactive_coverage_termination_maximum.to_hash }
      let(:earliest_retro_coverage_termination_date) {TimeKeeper.date_of_record.advance(termination_maximum).end_of_month }
      let(:earliest_valid_employment_termination_date) {earliest_retro_coverage_termination_date.beginning_of_month}
      let(:invalid_employment_termination_date) {earliest_valid_employment_termination_date - 1.day}
      let(:invalid_coverage_termination_date) {invalid_employment_termination_date.end_of_month}


      context "and the employment termination is reported later after max retroactive date" do

        before {initial_census_employee.terminate_employment!(invalid_employment_termination_date)}

        it "calculated coverage termination date should preceed the valid coverage termination date" do
          expect(invalid_coverage_termination_date).to be < earliest_retro_coverage_termination_date
        end

        it "is in terminated state" do
          expect(CensusEmployee.find(initial_census_employee.id).aasm_state).to eq "employment_terminated"
        end

        it "should have the correct employment termination date" do
          expect(CensusEmployee.find(initial_census_employee.id).employment_terminated_on).to eq invalid_employment_termination_date
        end

        it "should have the earliest coverage termination date" do
          expect(CensusEmployee.find(initial_census_employee.id).coverage_terminated_on).to eq earliest_retro_coverage_termination_date
        end

        context "and the user is HBX admin" do
          it "should use cancancan to permit admin termination"
        end
      end

      context "and the termination date is in the future" do
        before {initial_census_employee.terminate_employment!(TimeKeeper.date_of_record + 10.days)}
        it "is in termination pending state" do
          expect(CensusEmployee.find(initial_census_employee.id).aasm_state).to eq "employee_termination_pending"
        end
      end

      context ".terminate_future_scheduled_census_employees" do
        it "should terminate the census employee on the day of the termination date" do
          initial_census_employee.update_attributes(employment_terminated_on: TimeKeeper.date_of_record + 2.days, aasm_state: "employee_termination_pending")
          CensusEmployee.terminate_future_scheduled_census_employees(TimeKeeper.date_of_record + 2.days)
          expect(CensusEmployee.find(initial_census_employee.id).aasm_state).to eq "employment_terminated"
        end

        it "should not terminate the census employee if today's date < termination date" do
          initial_census_employee.update_attributes(employment_terminated_on: TimeKeeper.date_of_record + 2.days, aasm_state: "employee_termination_pending")
          CensusEmployee.terminate_future_scheduled_census_employees(TimeKeeper.date_of_record + 1.day)
          expect(CensusEmployee.find(initial_census_employee.id).aasm_state).to eq "employee_termination_pending"
        end

        it "should return the existing state of the census employee if today's date > termination date" do
          initial_census_employee.save
          initial_census_employee.update_attributes(employment_terminated_on: TimeKeeper.date_of_record + 2.days, aasm_state: "employment_terminated")
          CensusEmployee.terminate_future_scheduled_census_employees(TimeKeeper.date_of_record + 3.days)
          expect(CensusEmployee.find(initial_census_employee.id).aasm_state).to eq "employment_terminated"
        end

        it "should also terminate the census employees if termination date is in the past" do
          initial_census_employee.update_attributes(employment_terminated_on: TimeKeeper.date_of_record - 3.days, aasm_state: "employee_termination_pending")
          CensusEmployee.terminate_future_scheduled_census_employees(TimeKeeper.date_of_record)
          expect(CensusEmployee.find(initial_census_employee.id).aasm_state).to eq "employment_terminated"
        end
      end

      context "and the termination date is within the retroactive reporting time period" do
        before {initial_census_employee.terminate_employment!(earliest_valid_employment_termination_date)}

        it "is in terminated state" do
          expect(CensusEmployee.find(initial_census_employee.id).aasm_state).to eq "employment_terminated"
        end

        it "should have the correct employment termination date" do
          expect(CensusEmployee.find(initial_census_employee.id).employment_terminated_on).to eq earliest_valid_employment_termination_date
        end

        it "should have the earliest coverage termination date" do
          expect(CensusEmployee.find(initial_census_employee.id).coverage_terminated_on).to eq earliest_retro_coverage_termination_date
        end


        context "and the terminated employee is rehired" do
          let!(:rehire) {initial_census_employee.replicate_for_rehire}

          it "rehired census employee instance should have same demographic info" do
            expect(rehire.first_name).to eq initial_census_employee.first_name
            expect(rehire.last_name).to eq initial_census_employee.last_name
            expect(rehire.gender).to eq initial_census_employee.gender
            expect(rehire.ssn).to eq initial_census_employee.ssn
            expect(rehire.dob).to eq initial_census_employee.dob
            expect(rehire.employer_profile).to eq initial_census_employee.employer_profile
          end

          it "rehired census employee instance should be initialized state" do
            expect(rehire.eligible?).to be_truthy
            expect(rehire.hired_on).to_not eq initial_census_employee.hired_on
            expect(rehire.active_benefit_group_assignment.present?).to be_falsey
            expect(rehire.employee_role.present?).to be_falsey
          end

          it "the previously terminated census employee should be in rehired state" do
            expect(initial_census_employee.aasm_state).to eq "rehired"
          end
        end
      end
    end
  end

  context "multiple employers have active, terminated and rehired employees" do
    let(:today) {TimeKeeper.date_of_record}
    let(:one_month_ago) {today - 1.month}
    let(:last_month) {one_month_ago.beginning_of_month..one_month_ago.end_of_month}
    let(:last_year_to_date) {(today - 1.year)..today}

    let(:er1_active_employee_count) {2}
    let(:er1_terminated_employee_count) {1}
    let(:er1_rehired_employee_count) {1}

    let(:er2_active_employee_count) {1}
    let(:er2_terminated_employee_count) {1}

    let(:employee_count) do
      er1_active_employee_count +
        er1_terminated_employee_count +
        er1_rehired_employee_count +
        er2_active_employee_count +
        er2_terminated_employee_count
    end

    let(:terminated_today_employee_count) {2}
    let(:terminated_last_month_employee_count) {1}
    let(:er1_termination_count) {er1_terminated_employee_count + er1_rehired_employee_count}

    let(:terminated_employee_count) {er1_terminated_employee_count + er2_terminated_employee_count}
    let(:termed_status_employee_count) {terminated_employee_count + er1_rehired_employee_count}

    let(:employer_count) {2} # We're only creating 2 ER profiles

    let(:employer_profile_1) {abc_profile}
    let(:organization1) {abc_organization}

    let(:aasm_state) {:active}
    let(:package_kind) {:single_issuer}
    let(:effective_period) {current_effective_date..current_effective_date.next_year.prev_day}
    let(:open_enrollment_period) {effective_period.min.prev_month..(effective_period.min - 10.days)}
    let!(:employer_profile_2) {FactoryBot.create(:benefit_sponsors_organizations_aca_shop_cca_employer_profile, :with_organization_and_site, site: organization.site)}
    let(:organization2) {employer_profile_2.organization}
    let!(:benefit_sponsorship2) do
      sponsorship = employer_profile_2.add_benefit_sponsorship
      sponsorship.save
      sponsorship
    end
    let!(:service_areas2) {benefit_sponsorship2.service_areas_on(effective_period.min)}
    let(:benefit_sponsor_catalog2) {benefit_sponsorship2.benefit_sponsor_catalog_for(effective_period.min)}
    let(:initial_application2) do
      BenefitSponsors::BenefitApplications::BenefitApplication.new(
        benefit_sponsor_catalog: benefit_sponsor_catalog2,
        effective_period: effective_period,
        aasm_state: aasm_state,
        open_enrollment_period: open_enrollment_period,
        recorded_rating_area: rating_area,
        recorded_service_areas: service_areas2,
        fte_count: 5,
        pte_count: 0,
        msp_count: 0
      )
    end
    let(:product_package2) {initial_application.benefit_sponsor_catalog.product_packages.detect {|package| package.package_kind == package_kind}}
    let(:current_benefit_package2) {build(:benefit_sponsors_benefit_packages_benefit_package, health_sponsored_benefit: true, product_package: product_package2, benefit_application: initial_application2)}


    let(:er1_active_employees) do
      FactoryBot.create_list(
        :census_employee,
        er1_active_employee_count,
        employer_profile: employer_profile_1,
        benefit_sponsorship: organization1.active_benefit_sponsorship
      )
    end
    let(:er1_terminated_employees) do
      FactoryBot.create_list(
        :census_employee,
        er1_terminated_employee_count,
        employer_profile: employer_profile_1,
        benefit_sponsorship: organization1.active_benefit_sponsorship
      )
    end
    let(:er1_rehired_employees) do
      FactoryBot.create_list(
        :census_employee,
        er1_rehired_employee_count,
        employer_profile: employer_profile_1,
        benefit_sponsorship: organization1.active_benefit_sponsorship
      )
    end
    let(:er2_active_employees) do
      FactoryBot.create_list(
        :census_employee,
        er2_active_employee_count,
        employer_profile: employer_profile_2,
        benefit_sponsorship: organization2.active_benefit_sponsorship
      )
    end
    let(:er2_terminated_employees) do
      FactoryBot.create_list(
        :census_employee,
        er2_terminated_employee_count,
        employer_profile: employer_profile_2,
        benefit_sponsorship: organization2.active_benefit_sponsorship
      )
    end

    before do
      initial_application2.benefit_packages = [current_benefit_package2]
      benefit_sponsorship2.benefit_applications = [initial_application2]
      benefit_sponsorship2.save!

      er1_active_employees.each do |ee|
        ee.aasm_state = "employee_role_linked"
        ee.save!
      end

      er1_terminated_employees.each do |ee|
        ee.aasm_state = "employment_terminated"
        ee.employment_terminated_on = today
        ee.save!
      end

      er1_rehired_employees.each do |ee|
        ee.aasm_state = "rehired"
        ee.employment_terminated_on = today
        ee.save!
      end

      er2_active_employees.each do |ee|
        ee.aasm_state = "employee_role_linked"
        ee.save!
      end

      er2_terminated_employees.each do |ee|
        ee.aasm_state = "employment_terminated"
        ee.employment_terminated_on = one_month_ago
        ee.save!
      end
    end

    it "should find all employers" do
      expect(BenefitSponsors::Organizations::Organization.all.employer_profiles.size).to eq employer_count
    end

    it "should find all employees" do
      expect(CensusEmployee.all.size).to eq employee_count
    end

    context "and terminated employees are queried with no passed parameters" do
      it "should find the all employees terminated today" do
        expect(CensusEmployee.find_all_terminated.size).to eq terminated_today_employee_count
      end
    end

    context "and terminated employees who were terminated one month ago are queried" do
      it "should find the correct set" do
        expect(CensusEmployee.find_all_terminated(date_range: last_month).size).to eq terminated_last_month_employee_count
      end
    end

    context "and for one employer, the set of employees terminated since company joined the exchange are queried" do
      it "should find the correct set" do
        expect(CensusEmployee.find_all_terminated(employer_profiles: [employer_profile_1],
                                                  date_range: last_year_to_date).size).to eq er1_termination_count
      end
    end
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

  context "terminating census employee on the roster & actions on existing enrollments", dbclean: :around_each do

    context "change the aasm state & populates terminated on of enrollments" do

      let(:census_employee) do
        FactoryBot.create(
          :benefit_sponsors_census_employee,
          employer_profile: employer_profile,
          benefit_sponsorship: organization.active_benefit_sponsorship
        )
      end

      let(:employee_role) {FactoryBot.create(:benefit_sponsors_employee_role, employer_profile: employer_profile)}
      let(:family) {FactoryBot.create(:family, :with_primary_family_member)}

      let(:hbx_enrollment) {FactoryBot.create(:hbx_enrollment, family: family, sponsored_benefit_package_id: benefit_group.id, household: family.active_household, coverage_kind: 'health', employee_role_id: employee_role.id)}
      let(:hbx_enrollment_two) {FactoryBot.create(:hbx_enrollment, family: family, sponsored_benefit_package_id: benefit_group.id, household: family.active_household, coverage_kind: 'dental', employee_role_id: employee_role.id)}
      let(:hbx_enrollment_three) {FactoryBot.create(:hbx_enrollment, family: family, sponsored_benefit_package_id: benefit_group.id, household: family.active_household, aasm_state: 'renewing_waived', employee_role_id: employee_role.id)}
      let(:assignment) {double("BenefitGroupAssignment", benefit_package: benefit_group)}

      before do
        allow(census_employee).to receive(:active_benefit_group_assignment).and_return(assignment)
        allow(HbxEnrollment).to receive(:find_enrollments_by_benefit_group_assignment).and_return([hbx_enrollment, hbx_enrollment_two, hbx_enrollment_three], [])
        census_employee.update_attributes(employee_role_id: employee_role.id)
      end

      termination_dates = [TimeKeeper.date_of_record - 5.days, TimeKeeper.date_of_record, TimeKeeper.date_of_record + 5.days]
      termination_dates.each do |terminated_on|

        context 'move the enrollment into proper state' do

          before do
            # we do not want to trigger notice
            # takes too much time on processing
            allow_any_instance_of(BenefitSponsors::ModelEvents::HbxEnrollment).to receive(:notify_on_save).and_return(nil)
            census_employee.terminate_employment!(terminated_on)
          end

          it "should move the health enrollment to pending/terminated status" do
            coverage_end = census_employee.earliest_coverage_termination_on(terminated_on)
            if coverage_end < TimeKeeper.date_of_record
              expect(hbx_enrollment.reload.aasm_state).to eq 'coverage_terminated'
            else
              expect(hbx_enrollment.reload.aasm_state).to eq 'coverage_termination_pending'
            end
          end

          it "should set the coverage termination on date on the health enrollment" do
            expect(hbx_enrollment.reload.terminated_on).to eq census_employee.earliest_coverage_termination_on(terminated_on)
          end

          it "should move the dental enrollment to pending/terminated status" do
            coverage_end = census_employee.earliest_coverage_termination_on(terminated_on)
            if coverage_end < TimeKeeper.date_of_record
              expect(hbx_enrollment_two.reload.aasm_state).to eq 'coverage_terminated'
            else
              expect(hbx_enrollment_two.reload.aasm_state).to eq 'coverage_termination_pending'
            end
          end
        end

        context 'move the enrollment aasm state to cancel status' do

          before do
            hbx_enrollment.update_attribute(:effective_on, TimeKeeper.date_of_record.next_month)
            hbx_enrollment_two.update_attribute(:effective_on, TimeKeeper.date_of_record.next_month)
            # we do not want to trigger notice
            # takes too much time on processing
            allow_any_instance_of(BenefitSponsors::ModelEvents::HbxEnrollment).to receive(:notify_on_save).and_return(nil)
            census_employee.terminate_employment!(terminated_on)
          end

          it "should cancel the health enrollment if effective date is in future" do
            if census_employee.coverage_terminated_on < hbx_enrollment.effective_on
              expect(hbx_enrollment.reload.aasm_state).to eq 'coverage_canceled'
            else
              expect(hbx_enrollment.reload.aasm_state).to eq 'coverage_termination_pending'
            end
          end

          it "should set the coverage termination on date on the health enrollment" do
            if census_employee.coverage_terminated_on < hbx_enrollment.effective_on
              expect(hbx_enrollment.reload.terminated_on).to eq nil
            else
              expect(hbx_enrollment.reload.terminated_on).to eq census_employee.coverage_terminated_on
            end
          end

          it "should cancel the dental enrollment if effective date is in future" do
            if census_employee.coverage_terminated_on < hbx_enrollment.effective_on
              expect(hbx_enrollment.reload.aasm_state).to eq 'coverage_canceled'
            else
              expect(hbx_enrollment.reload.aasm_state).to eq 'coverage_termination_pending'
            end
          end

          it "should set the coverage termination on date on the dental enrollment" do
            if census_employee.coverage_terminated_on < hbx_enrollment.effective_on
              expect(hbx_enrollment_two.reload.terminated_on).to eq nil
            else
              expect(hbx_enrollment.reload.terminated_on).to eq census_employee.coverage_terminated_on
            end
          end
        end

        context 'move to enrollment aasm state to inactive state' do

          before do
            # we do not want to trigger notice
            # takes too much time on processing
            allow_any_instance_of(BenefitSponsors::ModelEvents::HbxEnrollment).to receive(:notify_on_save).and_return(nil)
            census_employee.terminate_employment!(terminated_on)
          end

          it "should move the waived enrollment to inactive state" do
            expect(hbx_enrollment_three.reload.aasm_state).to eq 'inactive' if terminated_on >= TimeKeeper.date_of_record
          end

          it "should set the coverage termination on date on the dental enrollment" do
            expect(hbx_enrollment_three.reload.terminated_on).to eq nil
          end
        end
      end
    end
  end

  context 'Validating CensusEmployee Termination Date' do
    let(:census_employee) {CensusEmployee.new(**valid_params)}

    it 'should return true when census employee is not terminated' do
      expect(census_employee.valid?).to be_truthy
    end

    it 'should return false when census employee date is not within 60 days' do
      census_employee.hired_on = TimeKeeper.date_of_record - 120.days
      census_employee.employment_terminated_on = TimeKeeper.date_of_record - 90.days
      expect(census_employee.valid?).to be_falsey
    end

    it 'should return true when census employee is already terminated' do
      census_employee.hired_on = TimeKeeper.date_of_record - 120.days
      census_employee.save! # set initial state
      census_employee.aasm_state = "employment_terminated"
      census_employee.employment_terminated_on = TimeKeeper.date_of_record - 90.days
      expect(census_employee.valid?).to be_truthy
    end
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