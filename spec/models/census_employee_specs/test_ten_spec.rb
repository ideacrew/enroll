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

describe "#is_cobra_possible" do
  let(:params) { valid_params.merge(:aasm_state => aasm_state) }
  let(:census_employee) { CensusEmployee.new(**params) }

  context "if censue employee is cobra linked" do
    let(:aasm_state) {"cobra_linked"}

    it "should return false" do
      expect(census_employee.is_cobra_possible?).to eq false
    end
  end

  context "if censue employee is cobra linked" do
    let(:aasm_state) {"employee_termination_pending"}

    it "should return false" do
      expect(census_employee.is_cobra_possible?).to eq true
    end
  end

  context "if censue employee is cobra linked" do
    let(:aasm_state) {"employment_terminated"}

    before do
      allow(census_employee).to receive(:employment_terminated_on).and_return TimeKeeper.date_of_record.last_month
    end

    it "should return false" do
      expect(census_employee.is_cobra_possible?).to eq true
    end
  end
end
end