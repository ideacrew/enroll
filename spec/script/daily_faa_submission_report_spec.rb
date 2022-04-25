# frozen_string_literal: true

require 'rails_helper'
require File.join(Rails.root, 'spec/shared_contexts/ivl_eligibility')

describe 'daily_faa_submission_report' do
  before do
    DatabaseCleaner.clean
  end
  include_context 'setup two tax households with one ia member each'

  let(:yesterday) { Time.now.getlocal.prev_day }
  let(:application) { FactoryBot.create(:financial_assistance_application, submitted_at: yesterday, family_id: family.id) }
  let(:applicants) do
    [FactoryBot.build(
      :financial_assistance_applicant,
      :with_home_address,
      application: application,
      family_member_id: family_member.id,
      is_primary_applicant: true,
      citizen_status: 'us_citizen'
    ),
     FactoryBot.build(
       :financial_assistance_applicant,
       :spouse,
       :with_home_address,
       application: application,
       family_member_id: family_member2.id,
       citizen_status: 'alien_lawfully_present'
     )]
  end
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
    ]
  end

  before :each do
    tax_household.update_attributes!(created_at: yesterday)
    tax_household2.update_attributes!(created_at: yesterday)
    application.applicants = applicants
    application.non_primary_applicants.each{|applicant| application.ensure_relationship_with_primary(applicant, applicant.relationship) }
    application.save
    person_params = person.attributes.slice("first_name", "last_name", "gender", "dob", "encrypted_ssn")
    person2_params = person2.attributes.slice("first_name", "last_name", "gender", "dob", "encrypted_ssn")
    application.applicants.first.update(person_params)
    application.applicants.last.update(person2_params)
    application.reload
    invoke_daily_faa_submission_report
    @file_content = CSV.read("#{Rails.root}/daily_faa_submission_report_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv")
  end

  it 'should add data to the file' do
    expect(@file_content.size).to be > 1
  end

  it 'should contain the requested fields' do
    expect(@file_content[0]).to eq(field_names)
  end

  context 'primary applicant' do
    it 'should match with the primary hbx id' do
      expect(@file_content[1][0]).to eq(application.primary_applicant.person_hbx_id.to_s)
    end

    it 'should match with the application hbx id' do
      expect(@file_content[1][1]).to eq(application.hbx_id.to_s)
    end

    it 'should match with the applicant age' do
      expect(@file_content[1][2]).to eq(primary_applicant.age_of_the_applicant.to_s)
    end

    it 'should match with the applicant uqhp determination' do
      expect(@file_content[1][3]).to eq(primary_applicant.is_without_assistance.to_s)
    end

    it 'should match with the applicant aptc/csr determination' do
      expect(@file_content[1][4]).to eq(primary_applicant.is_ia_eligible.to_s)
    end

    it 'should match with the max aptc' do
      expect(@file_content[1][5]).to eq format('%.2f', eligibilty_determination2.max_aptc.to_f)
    end

    it 'should match with the csr percent as integer' do
      expect(@file_content[1][6]).to eq(eligibilty_determination2.csr_percent_as_integer.to_s)
    end

    it 'should match with the applicant medicaid determination' do
      expect(@file_content[1][7]).to eq(primary_applicant.is_medicaid_chip_eligible.to_s)
    end

    it 'should match with the applicant non magi medicaid determination' do
      expect(@file_content[1][8]).to eq(primary_applicant.is_non_magi_medicaid_eligible.to_s)
    end

    it 'should match with the applicant totally ineligible determination' do
      expect(@file_content[1][9]).to eq(primary_applicant.is_totally_ineligible.to_s)
    end

    it 'should match with the application submission date' do
      expect(@file_content[1][10]).to eq(application.submitted_at.to_s)
    end

    it 'should match with the application full medicaid determination' do
      expect(@file_content[1][11]).to eq(application.full_medicaid_determination.to_s)
    end

    it 'should match with the applicant is blind indicator' do
      expect(@file_content[1][12]).to eq(primary_applicant.is_self_attested_blind.to_s)
    end

    it 'should match with the applicant is disabled indicator' do
      expect(@file_content[1][13]).to eq(primary_applicant.is_physically_disabled.to_s)
    end

    it 'should match with the applicant needs help with daily living indicator' do
      expect(@file_content[1][14]).to eq(primary_applicant.has_daily_living_help.to_s)
    end

    it 'should match with the applicant immigration status' do
      immigration_status = primary_applicant.citizen_status&.humanize&.downcase&.gsub("us", "US")
      expect(@file_content[1][15]).to eq(immigration_status)
    end
  end

  context 'spouse applicant in a separate tax household' do
    it 'should match with the primary hbx id' do
      expect(@file_content[2][0]).to eq(application.primary_applicant.person_hbx_id.to_s)
    end

    it 'should match with the application hbx id' do
      expect(@file_content[2][1]).to eq(application.hbx_id.to_s)
    end

    it 'should match with the applicant age' do
      expect(@file_content[2][2]).to eq(spouse_applicant.age_of_the_applicant.to_s)
    end

    it 'should match with the applicant uqhp determination' do
      expect(@file_content[2][3]).to eq(spouse_applicant.is_without_assistance.to_s)
    end

    it 'should match with the applicant aptc/csr determination' do
      expect(@file_content[2][4]).to eq(spouse_applicant.is_ia_eligible.to_s)
    end

    it 'should match with the max aptc' do
      expect(@file_content[2][5]).to eq format('%.2f', eligibilty_determination.max_aptc.to_f)
    end

    it 'should match with the csr percent as integer' do
      expect(@file_content[2][6]).to eq(eligibilty_determination.csr_percent_as_integer.to_s)
    end

    it 'should match with the applicant medicaid determination' do
      expect(@file_content[2][7]).to eq(spouse_applicant.is_medicaid_chip_eligible.to_s)
    end

    it 'should match with the applicant non magi medicaid determination' do
      expect(@file_content[2][8]).to eq(spouse_applicant.is_non_magi_medicaid_eligible.to_s)
    end

    it 'should match with the applicant totally ineligible determination' do
      expect(@file_content[2][9]).to eq(spouse_applicant.is_totally_ineligible.to_s)
    end

    it 'should match with the application submission date' do
      expect(@file_content[2][10]).to eq(application.submitted_at.to_s)
    end

    it 'should match with the application full medicaid determination' do
      expect(@file_content[2][11]).to eq(application.full_medicaid_determination.to_s)
    end

    it 'should match with the applicant is blind indicator' do
      expect(@file_content[2][12]).to eq(spouse_applicant.is_self_attested_blind.to_s)
    end

    it 'should match with the applicant is disabled indicator' do
      expect(@file_content[2][13]).to eq(spouse_applicant.is_physically_disabled.to_s)
    end

    it 'should match with the applicant needs help with daily living indicator' do
      expect(@file_content[2][14]).to eq(spouse_applicant.has_daily_living_help.to_s)
    end

    it 'should match with the applicant immigration status' do
      immigration_status = spouse_applicant.citizen_status&.humanize&.downcase&.gsub("us", "US")
      expect(@file_content[2][15]).to eq(immigration_status)
    end
  end

  after :each do
    FileUtils.rm_rf("#{Rails.root}/daily_eligibility_report_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv")
    FileUtils.rm_rf("#{Rails.root}/daily_eligibility_report_logger_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv")
  end
end

def invoke_daily_faa_submission_report
  daily_faa_submission_report = File.join(Rails.root, "script/daily_faa_submission_report.rb")
  load daily_faa_submission_report
end
