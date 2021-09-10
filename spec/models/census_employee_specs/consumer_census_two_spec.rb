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

  describe "#assign_prior_plan_benefit_packages", dbclean: :after_each do
    include_context "setup benefit market with market catalogs and product packages"
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
end