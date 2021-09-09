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