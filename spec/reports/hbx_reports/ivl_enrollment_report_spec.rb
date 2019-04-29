require "rails_helper"
require 'csv'
require File.join(Rails.root, "app", "reports", "hbx_reports", "ivl_enrollment_report")

describe IvlEnrollmentReport, dbclean: :after_each do
  let(:person) { FactoryGirl.create(:person, :with_consumer_role) }
  let(:active_household) { family.active_household }
  let!(:family) { FactoryGirl.create(:family, :with_primary_family_member_and_dependent, person: person)}
  let!(:primary) { family.primary_family_member }
  let!(:dependents) { family.dependents }
  let!(:employer_profile){  FactoryGirl.create(:employer_profile, aasm_state: "active")}
  let!(:employee_role) {FactoryGirl.create(:employee_role, person: person, employer_profile: employer_profile)}
  let!(:census_employee) { FactoryGirl.create(:census_employee, employee_role_id: employee_role.id, employer_profile_id: employer_profile.id) }
  let!(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: TimeKeeper.date_of_record.beginning_of_year, :aasm_state => 'active') }
  let!(:active_benefit_group) { FactoryGirl.create(:benefit_group, is_congress: false, plan_year: plan_year, title: "Benefits #{plan_year.start_on.year}") }
  let!(:benefit_group_assignment1)  { FactoryGirl.create(:benefit_group_assignment, census_employee: census_employee) }
  let!(:hbx_enrollment1) { FactoryGirl.create(:hbx_enrollment, household: family.active_household, :benefit_group_assignment => benefit_group_assignment1, employee_role_id: employee_role.id, benefit_group_id: active_benefit_group.id)}
  let(:hbx_enrollment) {FactoryGirl.create(:hbx_enrollment, household: active_household, coverage_kind: "health", effective_on: TimeKeeper.date_of_record.beginning_of_month, enrollment_kind: "open_enrollment", kind: "individual") }
  let!(:date) { TimeKeeper.date_of_record - 10.days }
  let!(:subscriber) { FactoryGirl.create(:hbx_enrollment_member, :hbx_enrollment => hbx_enrollment, eligibility_date: date, coverage_start_on: date, applicant_id: primary.id) }
  let!(:hbx_en_member1) { FactoryGirl.create(:hbx_enrollment_member, id: "111", hbx_enrollment: hbx_enrollment, eligibility_date: date, coverage_start_on: date, applicant_id: dependents.first.id) }
  subject { IvlEnrollmentReport.new("ivl_enrollment_report", double(:current_scope => nil)) }

  before :all do
    DatabaseCleaner.clean
  end

  before(:each) do
    allow(ENV).to receive(:[]).with("purchase_date_start").and_return('06/01/2017')
    allow(ENV).to receive(:[]).with("purchase_date_end").and_return('06/10/2019')
    hbx_enrollment.hbx_enrollment_members = [subscriber, hbx_en_member1]
    hbx_enrollment.save!
    hbx_enrollment1.hbx_enrollment_members = [subscriber, hbx_en_member1]
    hbx_enrollment1.save!
    subject.migrate
    @file = file_reader
  end

  it "creates csv file" do
    expect(@file.size).to be > 0
  end

  it "returns correct fields" do
    ivl_headers = ['Enrollment GroupID', 'Purchase Date', 'Coverage Start', 'Enrollment State', 'Subscriber HBXID',
                   'Subscriber First Name', 'Subscriber Last Name', 'HIOS ID', 'Family Size', 'Enrollment Reason',
                   'In Glue']
    expect(@file[0]).to eq ivl_headers
    expect(@file[1].present?).to eq true
  end

  def file_reader
    files = Dir.glob(File.join(Rails.root, 'ivl_enrollment_report.csv'))
    CSV.read files.first
  end

  after(:all) do
    FileUtils.rm("#{Rails.root}/ivl_enrollment_report.csv")
  end
end