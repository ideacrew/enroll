# frozen_string_literal: true

require 'rails_helper'

describe 'monthly_faa_submission_report' do
  before do
    DatabaseCleaner.clean
  end

  let(:person_dob_year) { Date.today.year - 48 }
  let!(:person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role, dob: Date.new(person_dob_year, 4, 4)) }
  let!(:person2) do
    member = FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role, dob: (person.dob - 10.years))
    person.ensure_relationship_with(member, 'spouse')
    member.save!
    member
  end

  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let!(:family_member) { family.primary_applicant }
  let!(:family_member2) { FactoryBot.create(:family_member, family: family, person: person2) }

  let!(:tax_household) { FactoryBot.create(:tax_household, household: family.active_household, effective_ending_on: nil) }
  let!(:tax_household_member) { FactoryBot.create(:tax_household_member, applicant_id: family_member.id, tax_household: tax_household) }
  let!(:tax_household2) { FactoryBot.create(:tax_household, household: family.active_household, effective_ending_on: nil) }
  let!(:tax_household_member2) { FactoryBot.create(:tax_household_member, applicant_id: family_member2.id, tax_household: tax_household2) }

  let!(:eligibility_determination) { FactoryBot.create(:eligibility_determination, max_aptc: 500.00, tax_household: tax_household, csr_eligibility_kind: 'csr_73') }
  let!(:eligibility_determination2) { FactoryBot.create(:eligibility_determination, max_aptc: 250.00, tax_household: tax_household2, csr_eligibility_kind: 'csr_87') }
  let(:eligibility_determinations) { [eligibility_determination, eligibility_determination2] }

  let(:last_month) { Time.now.getlocal.prev_month }
  let!(:application) do
    FactoryBot.create(
      :financial_assistance_application,
      submitted_at: last_month,
      family_id: family.id,
      eligibility_determinations: eligibility_determinations
    )
  end
  let!(:applicant) do
    FactoryBot.create(
      :financial_assistance_applicant,
      :with_home_address,
      application: application,
      family_member_id: family_member.id,
      is_primary_applicant: true,
      citizen_status: 'us_citizen',
      is_ia_eligible: true,
      is_medicaid_chip_eligible: false,
      csr_percent_as_integer: 73,
      first_name: person.first_name,
      last_name: person.last_name,
      gender: person.gender,
      dob: person.dob,
      encrypted_ssn: person.encrypted_ssn,
      eligibility_determination_id: eligibility_determination.id,
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
      first_name: person2.first_name,
      last_name: person2.last_name,
      gender: person2.gender,
      dob: person2.dob,
      encrypted_ssn: person.encrypted_ssn,
      eligibility_determination_id: eligibility_determination2.id,
      magi_as_percentage_of_fpl: 1.3
    )
  end
  let!(:applicants) { [applicant, applicant2] }

  let(:primary_applicant) { application.applicants.first }
  let(:spouse_applicant) { application.applicants.last }
  let(:field_names) do
    %w[
        Primary_HBX_ID
        Application_HBX_ID
        Age
        UQHP
        APTC_CSR
        APTC_Max
        CSR
        Magi_Medicaid
        Non_Magi
        Is_Totally_Ineligible
        Submitted_At
        Full_Medicaid_Applied?
        Blind
        Disabled
        Help_With_Daily_Living
        Immigration_Status
        FPL_Amount
    ]
  end

  before :each do
    application.non_primary_applicants.each{|applicant| application.ensure_relationship_with_primary(applicant, applicant.relationship) }
    invoke_monthly_faa_submission_report
    @file_content = CSV.read("#{Rails.root}/monthly_faa_submission_report_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv")
  end

  it 'should add data to the file' do
    expect(@file_content.size).to be > 1
  end

  it 'should contain the requested fields' do
    expect(@file_content[0]).to eq(field_names)
  end

  after :each do
    FileUtils.rm_rf("#{Rails.root}/monthly_eligibility_report_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv")
    FileUtils.rm_rf("#{Rails.root}/monthly_eligibility_report_logger_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv")
  end
end

def invoke_monthly_faa_submission_report
  monthly_faa_submission_report = File.join(Rails.root, "script/monthly_faa_submission_report.rb")
  load monthly_faa_submission_report
end
