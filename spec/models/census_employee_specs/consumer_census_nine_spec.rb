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