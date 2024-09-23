# frozen_string_literal: true

require 'rails_helper'

describe 'export_dmf_eligible_consumers_families' do
  include Dry::Monads[:result, :do]

  before do
    DatabaseCleaner.clean
  end

  let(:date) { TimeKeeper.date_of_record }
  let(:assistance_year) { date.year }
  let(:file_name) { "#{Rails.root}/export_dmf_eligible_consumers_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}_#{Time.now.in_time_zone('Eastern Time (US & Canada)').strftime('%H:%M:%S')}.csv" }

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
  let(:primary) {  FactoryBot.create(:person, :with_consumer_role, :with_ssn)}
  let(:primary_applicant) { family.primary_applicant }

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

  let(:family_member1) { family.family_members[0] }
  let(:family_member2) { family.family_members[1] }

  let(:yearly_expected_contribution_current) { 125.00 * 12 }
  let!(:eligibility_determination_current) do
    determination = family.create_eligibility_determination(effective_date: date.beginning_of_year)

    family.family_members.each do |family_member|
      subject = determination.subjects.create(
        gid: "gid://enroll/FamilyMember/#{family_member.id}",
        is_primary: family_member.is_primary_applicant,
        person_id: family_member.person.id
      )

      subject.eligibility_states.create(eligibility_item_key: 'health_product_enrollment_status', is_eligible: true)
    end

    determination.subjects[0].update(hbx_id: primary_applicant.hbx_id, encrypted_ssn: "Ih3m7vvmvWg7qcf1N6B6Hw==\n")
    determination.subjects[0].eligibility_states.create(eligibility_item_key: 'dental_product_enrollment_status', is_eligible: true)
    determination
  end

  let(:field_names) do
    [
      "Family Hbx ID",
      "Person Hbx ID",
      "Person First Name",
      "Person Last Name",
      "Has SSN?",
      "Has Valid SSN?",
      "Has Eligible Enrollment?",
      "Enrollment Hbx ID",
      "Enrollment Type",
      "Enrollment Status"
    ]
  end

  before :each do
    allow(EnrollRegistry[:alive_status].feature).to receive(:is_enabled).and_return(true)

    invoke_export_dmf_determination_eligible_consumers_report
    @file_content = CSV.read(file_name)
  end

  it 'should add data to the file' do
    expect(@file_content.size).to be > 1
  end

  it 'should contain the requested fields' do
    expect(@file_content[0]).to eq(field_names)
  end

  it 'should contain eligible consumer details' do
    consumer_content = [
      family.hbx_assigned_id.to_s,
      primary_applicant.hbx_id,
      primary_applicant.first_name,
      primary_applicant.last_name,
      'true',
      'true',
      'true',
      hbx_enrollment.hbx_id,
      'health, dental',
      hbx_enrollment.aasm_state
    ]

    expect(@file_content[1]).to eq(consumer_content)
  end

  it 'should does not include non-eligible members of Familes with eligibile members' do
    expect(@file_content[2]).to be_nil
  end

  after :each do
    FileUtils.rm_rf(file_name)
  end
end

def invoke_export_dmf_determination_eligible_consumers_report
  export_pvc_determined_families_report = File.join(Rails.root, "script/export_dmf_eligible_consumers.rb")
  load export_pvc_determined_families_report
end
