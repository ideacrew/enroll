require 'rails_helper'
require 'rake'

describe 'employer report have plan year' do

  before do
    DatabaseCleaner.clean
  end

  let!(:benefit_group) {FactoryGirl.create(:benefit_group)}
  let!(:active_plan_year) {FactoryGirl.build(:plan_year, start_on: TimeKeeper.date_of_record.beginning_of_year + 1.year, end_on: TimeKeeper.date_of_record.end_of_year + 1.year, aasm_state: 'active', benefit_groups: [benefit_group])}
  let!(:employer_profile) {FactoryGirl.build(:employer_profile, plan_years: [active_plan_year])}
  let!(:organization) {FactoryGirl.create(:organization, employer_profile: employer_profile)}
  let!(:build_plan_years_and_employees) {
    owner = FactoryGirl.create :census_employee, :owner, employer_profile: employer_profile
    employee_role = FactoryGirl.create :employee_role, employer_profile: employer_profile
    employee = FactoryGirl.create :census_employee, employer_profile: employer_profile
    employee.update(employee_role_id: employee_role.id)
    employee.add_benefit_group_assignment benefit_group, benefit_group.start_on
  }

  let!(:ce) {
    employer_profile.census_employees.non_business_owner.first
  }

  let!(:person) { FactoryGirl.create(:person, last_name: ce.last_name, first_name: ce.first_name)}
  let!(:employee_role)  {FactoryGirl.create(:employee_role, person: person, census_employee: ce, employer_profile: employer_profile)}
  let!(:ce_update) {ce.update_attributes({employee_role: employee_role})}
  let!(:family_rec) {Family.find_or_build_from_employee_role(employee_role)}
  let!(:hbx_enrollment_mem) {FactoryGirl.build(:hbx_enrollment_member, is_subscriber: true, eligibility_date:Time.now,applicant_id: person.primary_family.family_members.first.id,coverage_start_on:ce.active_benefit_group_assignment.benefit_group.start_on)}

  let!(:hbx_enrollment)  {FactoryGirl.create(:hbx_enrollment,
                       household: person.primary_family.active_household,
                       coverage_kind: "health",
                       effective_on: active_plan_year.start_on,
                       enrollment_kind: "open_enrollment",
                       kind: "employer_sponsored",
                       submitted_at: benefit_group.start_on - 20.days,
                       benefit_group_id: benefit_group.id,
                       employee_role_id: person.active_employee_roles.first.id,
                       benefit_group_assignment_id: ce.active_benefit_group_assignment.id,
                       plan_id: benefit_group.reference_plan.id,
                       aasm_state: 'coverage_selected',
                       hbx_enrollment_members:[hbx_enrollment_mem]
    )}

  let!(:family_reload) {family_rec.reload}

  context 'employer_profile' do

    before do
      load File.expand_path("#{Rails.root}/lib/tasks/generate_employers_report.rake", __FILE__)
      Rake::Task.define_task(:environment)
      ENV["py_start_on"] = "2019/01/01"
      ENV["py_end_on"] = "2019/12/31"
      ENV["hios_id"] = "41842"
      Rake::Task["generate_report:employers"].invoke()
    end

    it 'should generate report' do
      result = ['HBX_ID', 'FEIN', 'LEGAL_NAME', 'PLAN_YEAR_STATE', 'PLAN_YEAR_START_ON', 'PLAN_YEAR_END_ON', 'PLAN_HIOS_ID', 'PLAN_NAME', 'PLAN_MARKET', 'CARRIER_LEGAL_NAME']
      files = Dir.glob(File.join(Rails.root, "hbx_report", "employer_with_plan*.csv"))
      data = CSV.read files.first
      expect(data[0]).to eq result
      expect(data[1].present?).to eq true
      expect(data.count).to eq 2
    end
  end

  context 'census_employee' do

    before do
      ce.active_benefit_group_assignment.update_attributes(hbx_enrollment_id: hbx_enrollment.id)
      load File.expand_path("#{Rails.root}/lib/tasks/generate_employers_report.rake", __FILE__)
      Rake::Task.define_task(:environment)
      ENV["py_start_on"] = "2019/01/01"
      ENV["py_end_on"] = "2019/12/31"
      ENV["hios_id"] = "41842"
      Rake::Task["generate_report:enrollments"].reenable
      Rake::Task["generate_report:enrollments"].invoke()
    end

    it 'should generate report' do
      result = ['PERSON_HBX_ID',	'PERSON_FIRST_NAME',	'PERSON_LAST_NAME',	'CE_ID',	'ENROLLMENT_HBX_ID',	'ENROLLMENT_EFFECTIVE_ON',	'ENROLLMENT_AASM_STATE',	'CE_PLAN_NAME',	'CE_PLAN_HIOS_ID',	'ORG_HBX_ID',	'ORG_FEIN',	'ORG_LEGAL_NAME',	'PLAN_YEAR_STATE',	'PLAN_YEAR_START_ON',	'PLAN_YEAR_END_ON',	'ORG_PLAN_HIOS_ID',	'ORG_PLAN_NAME',	'ORG_PLAN_MARKET',	'CARRIER_LEGAL_NAME']
      files = Dir.glob(File.join(Rails.root, "hbx_report", "census_employee_with_plan*.csv"))
      data = CSV.read files.first
      expect(data[0]).to eq result
      expect(data[1].present?).to eq true
      expect(data.count).to eq 2
    end
  end

  after(:all) do
    dir_path = "#{Rails.root}/hbx_report/"
    Dir.foreach(dir_path) do |file|
      File.delete File.join(dir_path, file) if File.file?(File.join(dir_path, file))
    end
    Dir.delete(dir_path)
  end
end


