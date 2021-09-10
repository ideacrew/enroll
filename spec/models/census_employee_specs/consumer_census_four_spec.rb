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
      EnrollRegistry[:aca_shop_market].feature.stub(:is_enabled).and_return(true)
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

    it "should send email notification for non conversion employee" do
      allow(census_employee1).to receive(:active_benefit_group_assignment).and_return benefit_group_assignment
      person.employee_roles.create!(ssn: census_employee1.ssn,
                                    employer_profile_id: census_employee1.employer_profile.id,
                                    hired_on: census_employee1.hired_on)
      expect(census_employee1.send_invite!).to eq true
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

  context ".is_employee_in_term_pending?", dbclean: :after_each  do
    include_context "setup benefit market with market catalogs and product packages"
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
end