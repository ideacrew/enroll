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
end