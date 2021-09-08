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