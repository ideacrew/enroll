# frozen_string_literal: true

require 'rails_helper'

describe 'export_dmf_eligible_consumers_families' do
  before do
    DatabaseCleaner.clean
  end

  let(:date) { TimeKeeper.date_of_record }
  let(:assistance_year) { date.year }
  let(:csr) { ["87", "94"] }
  let(:filename) { "#{Rails.root}/export_dmf_eligible_consumers_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}_#{Time.now.in_time_zone('Eastern Time (US & Canada)').strftime('%H:%M:%S')}.csv" }

  let(:family) do
    family = FactoryBot.build(:family, person: primary)
    family.family_members = [
      FactoryBot.build(:family_member, is_primary_applicant: true, is_active: true, family: family, person: primary),
      FactoryBot.build(:family_member, is_primary_applicant: false, is_active: true, family: family, person: dependent)
    ]

    family.person.person_relationships.push PersonRelationship.new(relative_id: dependent.id, kind: 'spouse')
    family.save
    family
  end

  let(:dependent) { FactoryBot.create(:person) }
  let(:primary) {  FactoryBot.create(:person, :with_consumer_role)}
  let(:primary_applicant) { family.primary_applicant }
  let(:dependents) { family.dependents }
  let!(:tax_household_group_current) do
    family.tax_household_groups.create!(
      assistance_year: assistance_year,
      source: 'Admin',
      start_on: date.beginning_of_year,
      tax_households: [
        FactoryBot.build(:tax_household, household: family.active_household, effective_starting_on: date.beginning_of_year, effective_ending_on: TimeKeeper.date_of_record.end_of_year, max_aptc: 1000.00)
      ]
    )
  end

  let(:tax_household_current) do
    tax_household_group_current.tax_households.first
  end

  let!(:tax_household_member) { tax_household_current.tax_household_members.create(applicant_id: family.family_members[0].id, csr_percent_as_integer: 87, csr_eligibility_kind: "csr_87") }

  let!(:hbx_enrollment) do
    FactoryBot.create(:hbx_enrollment,
                      :individual_shopping,
                      :with_silver_health_product,
                      :with_enrollment_members,
                      enrollment_members: [primary_applicant],
                      effective_on: date.beginning_of_month,
                      family: family,
                      aasm_state: :coverage_selected,
                      applied_aptc_amount: 1000.00)
  end
  let!(:thh_start_on) { tax_household_current.effective_starting_on }

  let(:family_member1) { family.family_members[0] }
  let(:family_member2) { family.family_members[1] }
  let!(:ivl_enr_member2)   { FactoryBot.create(:hbx_enrollment_member, applicant_id: family_member2.id, hbx_enrollment: hbx_enrollment, eligibility_date: thh_start_on) }

  let(:yearly_expected_contribution_current) { 125.00 * 12 }
  let(:members_csr_set) { {family_member1 => '87', family_member2 => '87'} }
  let!(:eligibility_determination_current) do
    determination = family.create_eligibility_determination(effective_date: date.beginning_of_year)
    determination.grants.create(
      key: "AdvancePremiumAdjustmentGrant",
      value: yearly_expected_contribution_current,
      start_on: date.beginning_of_year,
      end_on: date.end_of_year,
      assistance_year: date.year,
      member_ids: family.family_members.map(&:id).map(&:to_s),
      tax_household_id: tax_household_current.id
    )

    members_csr_set.each do |family_member, csr_value|
      subject = determination.subjects.create(
        gid: "gid://enroll/FamilyMember/#{family_member.id}",
        is_primary: family_member.is_primary_applicant,
        person_id: family_member.person.id
      )

      state = subject.eligibility_states.create(eligibility_item_key: 'aptc_csr_credit')
      state.grants.create(
        key: "CsrAdjustmentGrant",
        value: csr_value,
        start_on: TimeKeeper.date_of_record.beginning_of_year,
        end_on: TimeKeeper.date_of_record.end_of_year,
        assistance_year: TimeKeeper.date_of_record.year,
        member_ids: family.family_members.map(&:id)
      )
    end

    determination
  end

  let(:yesterday) { Time.now.getlocal.prev_day }
  let!(:application) do
    FactoryBot.create(
      :financial_assistance_application,
      submitted_at: yesterday,
      family_id: family.id
    )
  end

  let!(:applicant) do
    FactoryBot.create(
      :financial_assistance_applicant,
      :with_home_address,
      application: application,
      family_member_id: family_member1.id,
      is_primary_applicant: true,
      citizen_status: 'us_citizen',
      is_ia_eligible: true,
      is_medicaid_chip_eligible: false,
      csr_percent_as_integer: 73,
      first_name: primary.first_name,
      last_name: primary.last_name,
      gender: primary.gender,
      dob: primary.dob,
      encrypted_ssn: primary.encrypted_ssn,
      magi_as_percentage_of_fpl: 1.3
    )
  end

  let!(:applicant2) do
    FactoryBot.create(
      :financial_assistance_applicant,
      :spouse,
      :with_home_address,
      application: application,
      family_member_id: family_member2.id,
      citizen_status: 'alien_lawfully_present',
      is_ia_eligible: false,
      is_medicaid_chip_eligible: true,
      csr_percent_as_integer: 87,
      first_name: dependent.first_name,
      last_name: dependent.last_name,
      gender: dependent.gender,
      dob: dependent.dob,
      encrypted_ssn: nil,
      magi_as_percentage_of_fpl: 1.3
    )
  end

  let(:field_names) do
    [
      "Family Hbx ID",
      "Person Hbx ID",
      "First Name",
      "Last Name",
      "Enrollment Type",
      "Enrollment Status"
    ]
  end

  before :each do
    application.non_primary_applicants.each{|applicant| application.ensure_relationship_with_primary(applicant, applicant.relationship) }
    invoke_export_dmf_determination_eligible_consumers_report
    @file_content = CSV.read(filename)
  end

  it 'should add data to the file' do
    expect(@file_content.size).to be > 1
  end

  it 'should contain the requested fields' do
    expect(@file_content[0]).to eq(field_names)
  end

  after :each do
    FileUtils.rm_rf(filename)
  end
end

def invoke_export_dmf_determination_eligible_consumers_report
  export_pvc_determined_families_report = File.join(Rails.root, "script/export_dmf_eligible_consumers.rb")
  load export_pvc_determined_families_report
end
