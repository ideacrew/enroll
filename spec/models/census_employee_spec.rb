# frozen_string_literal: true

require 'rails_helper'

require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"
require "#{Rails.root}/spec/models/shared_contexts/census_employee.rb"

RSpec.describe CensusEmployee, type: :model, dbclean: :around_each do

  before do
    DatabaseCleaner.clean
  end

  include_context "census employee base data"

  describe "Censusdependents validators" do
    let(:params) {valid_params}
    let(:initial_census_employee) {CensusEmployee.new(**params)}
    let(:dependent) {CensusDependent.new(first_name: 'David', last_name: 'Henry', ssn: "", employee_relationship: "spouse", dob: TimeKeeper.date_of_record - 30.years, gender: "male")}
    let(:dependent2) {FactoryBot.build(:census_dependent, employee_relationship: "child_under_26", ssn: 333_333_333, dob: TimeKeeper.date_of_record - 30.years, gender: "male")}

    it "allow dependent ssn's to be updated to nil" do
      initial_census_employee.census_dependents = [dependent]
      initial_census_employee.save!
      expect(initial_census_employee.census_dependents.first.ssn).to match(nil)
    end

    it "ignores dependent ssn's if ssn not nil" do
      initial_census_employee.census_dependents = [dependent2]
      initial_census_employee.save!
      expect(initial_census_employee.census_dependents.first.ssn).to match("333333333")
    end

    context "with duplicate ssn's on dependents" do
      let(:child1) {FactoryBot.build(:census_dependent, employee_relationship: "child_under_26", ssn: 333_333_333)}
      let(:child2) {FactoryBot.build(:census_dependent, employee_relationship: "child_under_26", ssn: 333_333_333)}

      it "should have errors" do
        initial_census_employee.census_dependents = [child1, child2]
        expect(initial_census_employee.save).to be_falsey
        expect(initial_census_employee.errors[:base].first).to match(/SSN's must be unique for each dependent and subscriber/)
      end
    end

    context "with duplicate blank ssn's on dependents" do
      let(:child1) {FactoryBot.build(:census_dependent, first_name: 'Jimmy', last_name: 'Stephens', employee_relationship: "child_under_26", ssn: "")}
      let(:child2) {FactoryBot.build(:census_dependent, first_name: 'Ally', last_name: 'Stephens', employee_relationship: "child_under_26", ssn: "")}

      it "should not have errors" do
        initial_census_employee.census_dependents = [child1, child2]
        expect(initial_census_employee.valid?).to be_truthy
      end
    end

    context "with ssn matching subscribers" do
      let(:child1) {FactoryBot.build(:census_dependent, employee_relationship: "child_under_26", ssn: initial_census_employee.ssn)}

      it "should have errors" do
        initial_census_employee.census_dependents = [child1]
        expect(initial_census_employee.save).to be_falsey
        expect(initial_census_employee.errors[:base].first).to match(/SSN's must be unique for each dependent and subscriber/)
      end
    end


    context "and census employee identifying info is edited" do
      before {initial_census_employee.ssn = "606060606"}

      it "should be be valid" do
        expect(initial_census_employee.valid?).to be_truthy
      end
    end
  end

  describe "When Employee Role" do
    let(:params) {valid_params}
    let(:initial_census_employee) {CensusEmployee.new(**params)}

    context "and a benefit group isn't yet assigned to employee" do
      it "the roster instance should not be ready for linking" do
        initial_census_employee.benefit_group_assignments.delete_all
        expect(initial_census_employee.may_link_employee_role?).to be_falsey
      end
    end

    context "and a benefit group is assigned to employee" do
      let(:benefit_group_assignment) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: benefit_group, census_employee: initial_census_employee)}

      before do
        initial_census_employee.benefit_group_assignments = [benefit_group_assignment]
        initial_census_employee.save
      end

      it "the employee census record should be ready for linking" do
        expect(initial_census_employee.may_link_employee_role?).to be_truthy
      end
    end

    context "and the benefit group plan year isn't published" do
      it "the roster instance should not be ready for linking" do
        benefit_application.cancel! if benefit_application.may_cancel?
        expect(initial_census_employee.may_link_employee_role?).to be_falsey
      end
    end
  end

  describe "When plan year is published" do
    let(:params) {valid_params}
    let(:initial_census_employee) {CensusEmployee.new(**params)}
    let(:benefit_group_assignment) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: benefit_group, census_employee: initial_census_employee)}

    context "and a roster match by SSN and DOB is performed" do

      before do
        initial_census_employee.benefit_group_assignments = [benefit_group_assignment]
        initial_census_employee.save
      end

      context "using non-matching ssn and dob" do
        let(:invalid_employee_role) {FactoryBot.build(:benefit_sponsors_employee_role, ssn: "777777777", dob: TimeKeeper.date_of_record - 5.days, employer_profile: employer_profile)}

        it "should return an empty array" do
          expect(CensusEmployee.matchable(invalid_employee_role.ssn, invalid_employee_role.dob)).to eq []
        end
      end

      context "using matching ssn and dob" do
        let(:valid_employee_role) {FactoryBot.build(:benefit_sponsors_employee_role, ssn: initial_census_employee.ssn, dob: initial_census_employee.dob, employer_profile: employer_profile)}
        let!(:user) {FactoryBot.create(:user, person: valid_employee_role.person)}

        it "should return the roster instance" do
          expect(CensusEmployee.matchable(valid_employee_role.ssn, valid_employee_role.dob).collect(&:id)).to eq [initial_census_employee.id]
        end

        context "and a link employee role request is received" do
          context "and the provided employee role identifying information doesn't match a census employee" do
            let(:invalid_employee_role) {FactoryBot.build(:benefit_sponsors_employee_role, ssn: "777777777", dob: TimeKeeper.date_of_record - 5.days, employer_profile: employer_profile)}

            it "should raise an error" do
              initial_census_employee.employee_role = invalid_employee_role
              expect(initial_census_employee.employee_role_linked?).to be_falsey
            end
          end

          context "and the provided employee role identifying information does match a census employee" do
            before do
              initial_census_employee.employee_role = valid_employee_role
            end

            it "should link the roster instance and employer role" do
              expect(initial_census_employee.employee_role_linked?).to be_truthy
            end

            context "and it is saved" do
              before {initial_census_employee.save}

              it "should no longer be available for linking" do
                expect(initial_census_employee.may_link_employee_role?).to be_falsey
              end

              it "should be findable by employee role" do
                expect(CensusEmployee.find_all_by_employee_role(valid_employee_role).size).to eq 1
                expect(CensusEmployee.find_all_by_employee_role(valid_employee_role).first).to eq initial_census_employee
              end

              it "and should be delinkable" do
                expect(initial_census_employee.may_delink_employee_role?).to be_truthy
              end

              it "should have a published benefit group" do
                expect(initial_census_employee.published_benefit_group).to eq benefit_group
              end
            end
          end
        end
      end
    end

    context "and employer is renewing" do
    end

    context 'When there are two active benefit applications' do
      let(:current_year) {TimeKeeper.date_of_record.year}
      let(:effective_period) {current_effective_date..current_effective_date.next_year.prev_day}
      let(:open_enrollment_period) {effective_period.min.prev_month..(effective_period.min - 10.days)}
      let!(:service_areas2) {benefit_sponsorship.service_areas_on(effective_period.min)}
      let!(:benefit_sponsor_catalog2) {benefit_sponsorship.benefit_sponsor_catalog_for(effective_period.min)}
      let!(:initial_application2) do
        BenefitSponsors::BenefitApplications::BenefitApplication.new(
          benefit_sponsor_catalog: benefit_sponsor_catalog2,
          effective_period: effective_period,
          aasm_state: :active,
          open_enrollment_period: open_enrollment_period,
          recorded_rating_area: rating_area,
          recorded_service_areas: service_areas2,
          fte_count: 5,
          pte_count: 0,
          msp_count: 0
        )
      end
      let(:product_package2) {initial_application.benefit_sponsor_catalog.product_packages.detect {|package| package.package_kind == package_kind}}
      let(:current_benefit_package2) {build(:benefit_sponsors_benefit_packages_benefit_package, health_sponsored_benefit: true, product_package: product_package2, title: "second benefit package", benefit_application: initial_application2)}


      before do
        FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: current_benefit_package2, census_employee: initial_census_employee)
        initial_application2.benefit_packages = [current_benefit_package2]
        benefit_sponsorship.benefit_applications = [initial_application2]
        benefit_sponsorship.save!
        initial_census_employee.save
      end

      it 'should only pick active benefit group assignment - first benefit package' do
        initial_census_employee.benefit_group_assignments[0].update_attributes(is_active: false, created_at: Date.new(current_year, 2, 21))
        initial_census_employee.benefit_group_assignments[1].update_attributes(is_active: true, created_at: Date.new(current_year - 1, 2, 21))
        expect(initial_census_employee.published_benefit_group.title).to eq 'first benefit package'
      end

      it 'should pick latest benefit group assignment if all the assignments are inactive' do
        initial_census_employee.benefit_group_assignments[0].update_attributes(is_active: false, created_at: Date.new(current_year, 2, 21))
        initial_census_employee.benefit_group_assignments[1].update_attributes(is_active: false, created_at: Date.new(current_year - 1, 2, 21))
        expect(initial_census_employee.published_benefit_group.title).to eq 'second benefit package'
      end

      it 'should only pick active benefit group assignment - second benefit package' do
        initial_census_employee.benefit_group_assignments[0].update_attributes(is_active: true, created_at: Date.new(current_year, 2, 21))
        initial_census_employee.benefit_group_assignments[1].update_attributes(is_active: false, created_at: Date.new(current_year - 1, 2, 21))
        expect(initial_census_employee.published_benefit_group.title).to eq 'second benefit package'
      end
    end
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
        allow(Rails).to receive_message_chain(:env, :test?).and_return false
        organization.active_benefit_sponsorship.update_attributes(source_kind: :conversion)
        person = employee_role.person
        person.user = user
        person.save
        census_employee.construct_employee_role
        census_employee.reload
      end
      it "should return true when link_employee_role!" do
        expect(census_employee.aasm_state).to eq('employee_role_linked')
      end

      it 'should send an invite' do
        expect(Invitation.all.size).to eq 1
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

  context "construct_employee_role_for_match_person" do
    let(:census_employee) do
      FactoryBot.create(
        :benefit_sponsors_census_employee,
        employer_profile: employer_profile,
        benefit_sponsorship: organization.active_benefit_sponsorship
      )
    end

    let(:person) do
      FactoryBot.create(
        :person,
        first_name: census_employee.first_name,
        last_name: census_employee.last_name,
        dob: census_employee.dob,
        ssn: census_employee.ssn,
        gender: census_employee.gender
      )
    end
    let(:census_employee1) {FactoryBot.build(:benefit_sponsors_census_employee, employer_profile: employer_profile, benefit_sponsorship: organization.active_benefit_sponsorship)}
    let(:benefit_group_assignment) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: benefit_group, census_employee: census_employee1)}


    it "should return false when not match person" do
      expect(census_employee1.construct_employee_role_for_match_person).to eq false
    end

    it "should return false when match person which has active employee role for current census employee" do
      allow(EnrollRegistry[:aca_shop_market].feature).to receive(:is_enabled).and_return(true)
      census_employee.update_attributes(benefit_sponsors_employer_profile_id: employer_profile.id)
      person.employee_roles.create!(ssn: census_employee.ssn,
                                    benefit_sponsors_employer_profile_id: census_employee.employer_profile.id,
                                    census_employee_id: census_employee.id,
                                    hired_on: census_employee.hired_on)
      expect(census_employee.construct_employee_role_for_match_person).to eq false
    end

    it "should return true when match person has no active employee roles for current census employee" do
      person.employee_roles.create!(ssn: census_employee.ssn,
                                    benefit_sponsors_employer_profile_id: census_employee.employer_profile.id,
                                    hired_on: census_employee.hired_on)
      expect(census_employee.construct_employee_role_for_match_person).to eq true
    end
  end



  context ".is_employee_in_term_pending?", dbclean: :after_each  do
    include_context "setup renewal application"

    let(:employer_profile) {abc_organization.employer_profile}
    let(:benefit_application) { abc_organization.employer_profile.benefit_applications.where(aasm_state: :active).first }

    let(:plan_year_start_on) {benefit_application.start_on}
    let(:plan_year_end_on) {benefit_application.end_on}

    let(:census_employee) do
      FactoryBot.create(:benefit_sponsors_census_employee,
                        benefit_sponsorship: employer_profile.active_benefit_sponsorship,
                        employer_profile: employer_profile,
                        created_at: (plan_year_start_on + 10.days),
                        updated_at: (plan_year_start_on + 10.days),
                        hired_on: (plan_year_start_on + 10.days))
    end

    it 'should return false if census employee is not terminated' do
      expect(census_employee.is_employee_in_term_pending?).to eq false
    end

    it 'should return false if census employee has no active benefit group assignment' do
      draft_benefit_group = abc_organization.employer_profile.benefit_applications.where(aasm_state: :draft).first.benefit_packages.first
      census_employee.benefit_group_assignments << BenefitGroupAssignment.new(benefit_group: draft_benefit_group, start_on: draft_benefit_group.benefit_application.start_on)
      expect(census_employee.is_employee_in_term_pending?).to eq false
    end

    it 'should return false if census employee is terminated but has no active benefit group assignment' do
      draft_benefit_group = abc_organization.employer_profile.benefit_applications.where(aasm_state: :draft).first.benefit_packages.first
      census_employee.update_attributes(employment_terminated_on: draft_benefit_group.end_on - 5.days)
      census_employee.benefit_group_assignments << BenefitGroupAssignment.new(benefit_group: draft_benefit_group, start_on: draft_benefit_group.benefit_application.start_on)
      expect(census_employee.is_employee_in_term_pending?).to eq false
    end

    it 'should return true if census employee is terminated with future date which falls under active PY' do
      active_benefit_package = census_employee.active_benefit_group_assignment.benefit_package
      census_employee.update_attributes(employment_terminated_on: active_benefit_package.end_on - 5.days)
      census_employee.benefit_group_assignments << BenefitGroupAssignment.new(benefit_group: active_benefit_package, start_on: active_benefit_package.benefit_application.start_on)
      expect(census_employee.is_employee_in_term_pending?).to eq true
    end

    it 'should return false if census employee has no active benefit group assignment' do
      active_benefit_package = census_employee.active_benefit_group_assignment.benefit_package
      census_employee.update_attributes(employment_terminated_on: active_benefit_package.end_on - 1.month)
      census_employee.existing_cobra = 'true'
      expect(census_employee.is_employee_in_term_pending?).to eq false
    end
  end

  context "generate_and_deliver_checkbook_url" do
    let(:census_employee) do
      FactoryBot.create(
        :benefit_sponsors_census_employee,
        employer_profile: employer_profile,
        benefit_sponsorship: organization.active_benefit_sponsorship
      )
    end

    let(:hbx_enrollment) {HbxEnrollment.new(coverage_kind: 'health', family: family)}
    let(:plan) {FactoryBot.create(:plan)}
    let(:builder_class) {"ShopEmployerNotices::OutOfPocketNotice"}
    let(:builder) {instance_double(builder_class, :deliver => true)}
    let(:notice_triggers) {double("notice_triggers")}
    let(:notice_trigger) {instance_double("NoticeTrigger", :notice_template => "template", :mpi_indicator => "mpi_indicator")}

    before do
      allow(employer_profile).to receive(:plan_years).and_return([benefit_application])
      allow(census_employee).to receive(:employer_profile).and_return(employer_profile)
      allow(census_employee).to receive_message_chain(:employer_profile, :plan_years).and_return([benefit_application])
      allow(census_employee).to receive_message_chain(:active_benefit_group, :reference_plan).and_return(plan)
      allow(notice_triggers).to receive(:first).and_return(notice_trigger)
      allow(notice_trigger).to receive_message_chain(:notice_builder, :classify).and_return(builder_class)
      allow(notice_trigger).to receive_message_chain(:notice_builder, :safe_constantize, :new).and_return(builder)
      allow(notice_trigger).to receive_message_chain(:notice_trigger_element_group, :notice_peferences).and_return({})
      allow(ApplicationEventKind).to receive_message_chain(:where, :first).and_return(double("ApplicationEventKind", {:notice_triggers => notice_triggers, :title => "title", :event_name => "OutOfPocketNotice"}))
      allow_any_instance_of(Services::CheckbookServices::PlanComparision).to receive(:generate_url).and_return("fake_url")
    end
    context "#generate_and_deliver_checkbook_url" do
      it "should create a builder and deliver without expection" do
        expect {census_employee.generate_and_deliver_checkbook_url}.not_to raise_error
      end

      it 'should trigger deliver' do
        expect(builder).to receive(:deliver)
        census_employee.generate_and_deliver_checkbook_url
      end
    end

    context "#generate_and_save_to_temp_folder " do
      it "should builder and save without expection" do
        expect {census_employee.generate_and_save_to_temp_folder}.not_to raise_error
      end

      it 'should not trigger deliver' do
        expect(builder).not_to receive(:deliver)
        census_employee.generate_and_save_to_temp_folder
      end
    end
  end



  context '.earliest_eligible_date' do
    let(:hired_on) {TimeKeeper.date_of_record}

    let(:census_employee) {CensusEmployee.new(**valid_params)}
    let(:benefit_group_assignment) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: benefit_group, census_employee: census_employee)}

    before do
      census_employee.benefit_group_assignments = [benefit_group_assignment]
      census_employee.save!
      # benefit_group.plan_year.update_attributes(:aasm_state => 'published')
    end

    it 'should return earliest effective date' do
      # TODO: - Fix Effective On For & Eligible On on benefit package
      eligible_date = (hired_on + 60.days)
      eligible_date = (hired_on + 60.days).end_of_month + 1.day if eligible_date.day != 1
      # expect(census_employee.earliest_eligible_date).to eq eligible_date
    end
  end

  context "current_state" do
    let(:census_employee) {CensusEmployee.new}

    context "existing_cobra is true" do
      before :each do
        census_employee.existing_cobra = 'true'
      end

      it "should return cobra_terminated" do
        census_employee.aasm_state = CensusEmployee::COBRA_STATES.last
        expect(census_employee.current_state).to eq CensusEmployee::COBRA_STATES.last.humanize
      end
    end

    context "existing_cobra is false" do
      it "should return aasm_state" do
        expect(census_employee.current_state).to eq 'eligible'.humanize
      end
    end
  end

  context "show_plan_end_date?" do
    context "without coverage_terminated_on" do

      let(:census_employee) do
        FactoryBot.build(
          :benefit_sponsors_census_employee,
          employer_profile: employer_profile,
          benefit_sponsorship: organization.active_benefit_sponsorship,
          hired_on: hired_on
        )
      end

      (CensusEmployee::EMPLOYMENT_TERMINATED_STATES + CensusEmployee::COBRA_STATES).uniq.each do |state|
        it "should return false when aasm_state is #{state}" do
          census_employee.aasm_state = state
          expect(census_employee.show_plan_end_date?).to be_falsey
        end
      end
    end

    context "with coverage_terminated_on" do

      let(:census_employee) do
        FactoryBot.create(
          :benefit_sponsors_census_employee,
          employer_profile: employer_profile,
          benefit_sponsorship: organization.active_benefit_sponsorship,
          coverage_terminated_on: TimeKeeper.date_of_record
        )
      end

      CensusEmployee::EMPLOYMENT_TERMINATED_STATES.each do |state|
        it "should return false when aasm_state is #{state}" do
          census_employee.aasm_state = state
          expect(census_employee.show_plan_end_date?).to be_truthy
        end
      end

      (CensusEmployee::COBRA_STATES - CensusEmployee::EMPLOYMENT_TERMINATED_STATES).each do |state|
        it "should return false when aasm_state is #{state}" do
          census_employee.aasm_state = state
          expect(census_employee.show_plan_end_date?).to be_falsey
        end
      end
    end
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

  context ".is_waived_under?" do
    let(:census_employee) {CensusEmployee.new(**valid_params)}
    let!(:benefit_group_assignment) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: benefit_group, census_employee: census_employee)}
    let(:family) {FactoryBot.create(:family, :with_primary_family_member)}

    before do
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

    context "when bga default hbx_enrollment has coverage_kind dental" do
      before do
        dental_enrollment = FactoryBot.create(:hbx_enrollment, :with_dental_coverage_kind, family: family, household: family.active_household, benefit_group_assignment_id: benefit_group_assignment.id)
        allow(benefit_group_assignment).to receive(:hbx_enrollment).and_return(dental_enrollment)
      end

      it "should return false if employee has not waived health coverage" do
        expect(census_employee.is_waived_under?(benefit_group_assignment.benefit_application)).to be_falsey
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

  describe "#trigger_notice" do
    let(:census_employee) {FactoryBot.build(:benefit_sponsors_census_employee, employer_profile: employer_profile, benefit_sponsorship: organization.active_benefit_sponsorship)}
    let(:employee_role) {FactoryBot.build(:benefit_sponsors_employee_role, :census_employee => census_employee)}
    it "should trigger job in queue" do
      ActiveJob::Base.queue_adapter = :test
      ActiveJob::Base.queue_adapter.enqueued_jobs = []
      census_employee.trigger_notice("ee_sep_request_accepted_notice")
      queued_job = ActiveJob::Base.queue_adapter.enqueued_jobs.find do |job_info|
        job_info[:job] == ShopNoticesNotifierJob
      end
      expect(queued_job[:args]).to eq [census_employee.id.to_s, 'ee_sep_request_accepted_notice']
    end
  end

  describe "search_hash" do
    context 'census search query' do

      it "query string for census employee firstname or last name" do
        employee_search = "test1"
        expected_result = {"$or" => [{"$or" => [{"first_name" => /test1/i}, {"last_name" => /test1/i}]}, {"encrypted_ssn" => "+MZq0qWj9VdyUd9MifJWpQ==\n"}]}
        result = CensusEmployee.search_hash(employee_search)
        expect(result).to eq expected_result
      end

      it "census employee query string for full name" do
        employee_search = "test1 test2"
        expected_result = {"$or" => [{"$and" => [{"first_name" => /test1|test2/i}, {"last_name" => /test1|test2/i}]}, {"encrypted_ssn" => "0m50gjJW7mR4HLnepJyFmg==\n"}]}
        result = CensusEmployee.search_hash(employee_search)
        expect(result).to eq expected_result
      end

    end
  end



  describe "#is_rehired_possible" do
    let(:params) { valid_params.merge(:aasm_state => aasm_state) }
    let(:census_employee) { CensusEmployee.new(**params) }

    context "if censue employee is cobra linked" do
      let(:aasm_state) {"cobra_eligible"}

      it "should return false" do
        expect(census_employee.is_rehired_possible?).to eq false
      end
    end

    context "if censue employee is cobra linked" do
      let(:aasm_state) {"rehired"}

      it "should return false" do
        expect(census_employee.is_rehired_possible?).to eq false
      end
    end

    context "if censue employee is cobra linked" do
      let(:aasm_state) {"cobra_terminated"}

      it "should return false" do
        expect(census_employee.is_rehired_possible?).to eq true
      end
    end
  end


  describe "Employee enrolling for cobra" do

    context "and employer reinstate employee as cobra", dbclean: :after_each do

      include_context "setup expired, expired and active benefit applications"
      let(:current_effective_date) { Date.new(TimeKeeper.date_of_record.year - 1, 6, 1)}

      let(:coverage_kind) { 'health' }
      let(:hired_on) { TimeKeeper.date_of_record - 3.years }

      let(:user) { FactoryBot.create(:user)}
      let(:person) {FactoryBot.create(:person, user: user)}

      let(:shop_family) {FactoryBot.create(:family, :with_primary_family_member, person: person)}

      let!(:census_employee) do
        census_employee = create(:census_employee, :with_active_assignment, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile, benefit_group: active_benefit_package, hired_on: hired_on,
                                                                            employee_role_id: employee_role.id)
        census_employee.create_benefit_package_assignment(expired_benefit_package_two, expired_benefit_package_two.start_on)
        assignment = census_employee.create_benefit_package_assignment(expired_benefit_package_one, expired_benefit_package_one.start_on)
        assignment.is_active = true
        assignment.save
        census_employee.reload
      end

      let(:employee_role) { FactoryBot.create(:employee_role, benefit_sponsors_employer_profile_id: abc_profile.id, hired_on: hired_on, person: person) }

      let!(:expired_enrollment_one) do
        FactoryBot.create(:hbx_enrollment,
                          household: shop_family.latest_household,
                          coverage_kind: coverage_kind,
                          effective_on: expired_benefit_application_one.start_on,
                          enrollment_kind: 'open_enrollment',
                          family: shop_family,
                          kind: "employer_sponsored",
                          submitted_at: expired_benefit_application_one.start_on - 20.days,
                          benefit_sponsorship_id: benefit_sponsorship.id,
                          sponsored_benefit_package_id: expired_benefit_package_one.id,
                          sponsored_benefit_id: expired_sponsored_benefit_one.id,
                          employee_role_id: employee_role.id,
                          benefit_group_assignment_id: census_employee.benefit_package_assignment_on(expired_benefit_package_one.start_on).id,
                          product_id: expired_sponsored_benefit_one.reference_product.id,
                          aasm_state: 'expired')
      end

      let!(:expired_enrollment_two) do
        FactoryBot.create(:hbx_enrollment,
                          household: shop_family.latest_household,
                          coverage_kind: coverage_kind,
                          effective_on: expired_benefit_application_two.start_on,
                          enrollment_kind: 'open_enrollment',
                          family: shop_family,
                          kind: "employer_sponsored",
                          submitted_at: expired_benefit_application_two.start_on - 20.days,
                          benefit_sponsorship_id: benefit_sponsorship.id,
                          sponsored_benefit_package_id: expired_benefit_package_two.id,
                          sponsored_benefit_id: expired_sponsored_benefit_two.id,
                          employee_role_id: employee_role.id,
                          benefit_group_assignment_id: census_employee.benefit_package_assignment_on(expired_benefit_package_two.start_on).id,
                          product_id: expired_sponsored_benefit_two.reference_product.id,
                          aasm_state: 'expired')
      end

      let(:employment_termination_date) { active_benefit_application.start_on + 15.days }

      context "when employee enrolled previously", dbclean: :after_each do

        let!(:active_enrollment) do
          FactoryBot.create(:hbx_enrollment,
                            household: shop_family.latest_household,
                            coverage_kind: coverage_kind,
                            effective_on: active_benefit_application.start_on,
                            enrollment_kind: 'open_enrollment',
                            family: shop_family,
                            kind: "employer_sponsored",
                            submitted_at: active_benefit_application.start_on - 20.days,
                            benefit_sponsorship_id: benefit_sponsorship.id,
                            sponsored_benefit_package_id: active_benefit_package.id,
                            sponsored_benefit_id: active_sponsored_benefit.id,
                            employee_role_id: employee_role.id,
                            benefit_group_assignment_id: census_employee.benefit_package_assignment_on(active_benefit_package.start_on).id,
                            product_id: active_sponsored_benefit.reference_product.id,
                            aasm_state: 'coverage_selected')
        end

        let(:cobra_begin_date) { employment_termination_date.end_of_month + 1.day }

        before do
          TimeKeeper.set_date_of_record_unprotected!(active_benefit_application.start_on.next_month + 15.days)
          employee_role.update(census_employee_id: census_employee.id)
          allow(census_employee).to receive(:employee_record_claimed?).and_return(true)
          census_employee.employee_role = (employee_role)
          census_employee.terminate_employment(employment_termination_date)
          census_employee.reload
          census_employee.update_for_cobra(cobra_begin_date, user)
          census_employee.reload
        end

        after do
          TimeKeeper.set_date_of_record_unprotected!(Date.today)
        end

        it 'should reinstate employee cobra coverage' do
          shop_family.reload
          cobra_enrollment = shop_family.active_household.hbx_enrollments.where(:effective_on => cobra_begin_date).first
          expect(cobra_enrollment).to be_present
        end

        it 'should create new valid benefit group assignment' do
          assignment = census_employee.benefit_group_assignments.where(start_on: cobra_begin_date).first
          expect(assignment).to be_present
        end
      end


      context "when cobra effective date is last month of PY and terminated previously with renewing cancelled enrollment", dbclean: :after_each do
        let(:renewal_effective_date) {active_benefit_application.end_on + 1.day}
        let(:renewal_effective_period) {renewal_effective_date..current_effective_date.next_year.prev_day}
        let(:renewal_benefit_application) {expired_benefit_application_one.update_attributes(aasm_state: :canceled, effective_period: renewal_effective_period)}
        let(:renewal_benefit_package) { expired_benefit_package_one }
        let!(:active_enrollment) do
          FactoryBot.create(:hbx_enrollment,
                            household: shop_family.latest_household,
                            coverage_kind: coverage_kind,
                            effective_on: active_benefit_application.start_on,
                            enrollment_kind: 'open_enrollment',
                            family: shop_family,
                            kind: "employer_sponsored",
                            submitted_at: active_benefit_application.start_on - 20.days,
                            benefit_sponsorship_id: benefit_sponsorship.id,
                            sponsored_benefit_package_id: active_benefit_package.id,
                            sponsored_benefit_id: active_sponsored_benefit.id,
                            employee_role_id: employee_role.id,
                            benefit_group_assignment_id: census_employee.benefit_package_assignment_on(active_benefit_package.start_on).id,
                            product_id: active_sponsored_benefit.reference_product.id,
                            aasm_state: 'coverage_selected')
        end

        let!(:renewing_cancelled_enrollment) do
          FactoryBot.create(:hbx_enrollment,
                            household: shop_family.latest_household,
                            coverage_kind: coverage_kind,
                            effective_on: renewal_effective_date,
                            enrollment_kind: 'open_enrollment',
                            family: shop_family,
                            kind: "employer_sponsored",
                            submitted_at: expired_benefit_application_one.start_on - 20.days,
                            benefit_sponsorship_id: benefit_sponsorship.id,
                            sponsored_benefit_package_id: renewal_benefit_package.id,
                            sponsored_benefit_id: expired_sponsored_benefit_one.id,
                            employee_role_id: employee_role.id,
                            benefit_group_assignment_id: census_employee.benefit_package_assignment_on(renewal_benefit_package.start_on).id,
                            product_id: expired_sponsored_benefit_one.reference_product.id,
                            aasm_state: 'canceled')
        end

        let(:employment_termination_date) { active_benefit_application.end_on - 2.months }
        let(:cobra_begin_date) { employment_termination_date.end_of_month + 1.day }

        before do
          TimeKeeper.set_date_of_record_unprotected!(active_benefit_application.end_on - 1.month)
          employee_role.update(census_employee_id: census_employee.id)
          allow(census_employee).to receive(:employee_record_claimed?).and_return(true)
          assignment = census_employee.create_benefit_package_assignment(renewal_benefit_package, renewal_benefit_package.start_on)
          assignment.save
          census_employee.employee_role = (employee_role)
          census_employee.terminate_employment(employment_termination_date)
          census_employee.reload
          census_employee.update_for_cobra(cobra_begin_date, user)
          census_employee.reload
        end

        after do
          TimeKeeper.set_date_of_record_unprotected!(Date.today)
        end

        it 'should reinstate employee cobra coverage' do
          shop_family.reload
          cobra_enrollment = shop_family.active_household.hbx_enrollments.where(:effective_on => cobra_begin_date).first
          expect(cobra_enrollment).to be_present
        end

        it 'should create new valid benefit group assignment' do
          assignment = census_employee.benefit_group_assignments.where(start_on: cobra_begin_date).first
          expect(assignment).to be_present
        end
      end

    end

    context "cobra with auto renewal enrollments", dbclean: :after_each do
      include_context "setup expired, active and renewing benefit applications"

      let!(:current_benefit_market_catalog) do
        ::BenefitSponsors::ProductSpecHelpers.construct_benefit_market_catalog_with_renewal_and_previous_catalog(
          site,
          benefit_market,
          (TimeKeeper.date_of_record.beginning_of_year..TimeKeeper.date_of_record.end_of_year)
        )
        benefit_market.benefit_market_catalogs.where(
          "application_period.min" => TimeKeeper.date_of_record.beginning_of_year
        ).first
      end
      let(:current_effective_date) { Date.new(TimeKeeper.date_of_record.year - 1, 6, 1)}

      let(:coverage_kind) { 'health' }
      let(:hired_on) { TimeKeeper.date_of_record - 3.years }

      let(:user) { FactoryBot.create(:user)}
      let(:person) {FactoryBot.create(:person, user: user)}

      let(:shop_family) {FactoryBot.create(:family, :with_primary_family_member, person: person)}

      let!(:census_employee) do
        census_employee = create(:census_employee, :with_active_assignment, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile, benefit_group: active_benefit_package, hired_on: hired_on,
                                                                            employee_role_id: employee_role.id)
        assignment = census_employee.create_benefit_package_assignment(expired_benefit_package, expired_benefit_package.start_on)
        assignment.is_active = true
        assignment.save
        assignment = census_employee.create_benefit_package_assignment(renewal_benefit_package, renewal_benefit_package.start_on)
        assignment.is_active = true
        assignment.save
        census_employee.reload
      end

      let(:employee_role) { FactoryBot.create(:employee_role, benefit_sponsors_employer_profile_id: abc_profile.id, hired_on: hired_on, person: person) }

      let(:employment_termination_date) { active_benefit_application.start_on + 15.days }
      let!(:active_enrollment) do
        FactoryBot.create(:hbx_enrollment,
                          household: shop_family.latest_household,
                          coverage_kind: coverage_kind,
                          effective_on: active_benefit_application.start_on,
                          enrollment_kind: 'open_enrollment',
                          family: shop_family,
                          kind: "employer_sponsored",
                          submitted_at: active_benefit_application.start_on - 20.days,
                          benefit_sponsorship_id: benefit_sponsorship.id,
                          sponsored_benefit_package_id: active_benefit_package.id,
                          sponsored_benefit_id: active_sponsored_benefit.id,
                          employee_role_id: employee_role.id,
                          benefit_group_assignment_id: census_employee.benefit_package_assignment_on(active_benefit_package.start_on).id,
                          product_id: active_sponsored_benefit.reference_product.id,
                          aasm_state: 'coverage_enrolled')
      end

      let!(:renewing_enrollment) do
        FactoryBot.create(:hbx_enrollment,
                          household: shop_family.latest_household,
                          coverage_kind: coverage_kind,
                          effective_on: renewal_benefit_application.start_on,
                          enrollment_kind: 'open_enrollment',
                          family: shop_family,
                          kind: "employer_sponsored",
                          submitted_at: renewal_benefit_application.start_on - 20.days,
                          benefit_sponsorship_id: benefit_sponsorship.id,
                          sponsored_benefit_package_id: renewal_benefit_package.id,
                          sponsored_benefit_id: renewal_sponsored_benefit.id,
                          employee_role_id: employee_role.id,
                          benefit_group_assignment_id: census_employee.benefit_package_assignment_on(renewal_benefit_package.start_on).id,
                          product_id: renewal_sponsored_benefit.reference_product.id,
                          aasm_state: 'auto_renewing')
      end

      let(:employment_termination_date) { active_benefit_application.end_on - 2.months }
      let(:cobra_begin_date) { employment_termination_date.end_of_month + 1.day }

      before do
        TimeKeeper.set_date_of_record_unprotected!(active_benefit_application.end_on - 1.month)
        employee_role.update(census_employee_id: census_employee.id)
        allow(census_employee).to receive(:employee_record_claimed?).and_return(true)
        census_employee.employee_role = (employee_role)
        census_employee.terminate_employment(employment_termination_date)
        census_employee.reload
        census_employee.update_for_cobra(cobra_begin_date, user)
        census_employee.reload
      end

      after do
        TimeKeeper.set_date_of_record_unprotected!(Date.today)
      end

      it 'should create active and auto renewal enrollments when cobra is initiated' do
        shop_family.reload

        auto_renewing_enrollments = HbxEnrollment.all.where(aasm_state: 'auto_renewing')
        expect(auto_renewing_enrollments.size).to eq(1)
        auto_renewing_enrollment = auto_renewing_enrollments.last
        expect(auto_renewing_enrollment.effective_on).to eq(renewing_enrollment.effective_on)

        active_enrollments = HbxEnrollment.all.where(aasm_state: 'coverage_enrolled')
        expect(active_enrollments.size).to eq(1)
        active_enrollment = active_enrollments.last
        expect(active_enrollment.effective_on).to eq(active_enrollment.effective_on)
      end
    end
  end

  describe 'callbacks' do
    context '.publish_employee_created' do
      let(:census_employee) do
        build(
          :benefit_sponsors_census_employee,
          employer_profile: employer_profile,
          benefit_sponsorship: employer_profile.active_benefit_sponsorship
        )
      end

      it 'should call publish_employee_created' do
        expect(census_employee).to receive(:publish_employee_created)
        census_employee.save!
      end
    end
  end

  context "download_census_employees_roster" do
    it "should not export SSN column to the report" do
      response = CensusEmployee.download_census_employees_roster(employer_profile.id)
      expect(response).is_a?(String)
      expect(response).to_not include("SSN / TIN (Required for EE & enter without dashes)")
    end
  end
end
