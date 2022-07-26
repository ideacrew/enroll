# frozen_string_literal: true

require 'rails_helper'

describe 'applicant_outreach_report' do
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

#   let!(:tax_household) { FactoryBot.create(:tax_household, household: family.active_household, effective_ending_on: nil) }
#   let!(:tax_household_member) { FactoryBot.create(:tax_household_member, applicant_id: family_member.id, tax_household: tax_household) }
#   let!(:tax_household2) { FactoryBot.create(:tax_household, household: family.active_household, effective_ending_on: nil) }
#   let!(:tax_household_member2) { FactoryBot.create(:tax_household_member, applicant_id: family_member2.id, tax_household: tax_household2) }

#   let!(:eligibility_determination) { FactoryBot.create(:eligibility_determination, max_aptc: 500.00, tax_household: tax_household, csr_eligibility_kind: 'csr_73') }
#   let!(:eligibility_determination2) { FactoryBot.create(:eligibility_determination, max_aptc: 250.00, tax_household: tax_household2, csr_eligibility_kind: 'csr_87') }
#   let(:eligibility_determinations) { [eligibility_determination, eligibility_determination2] }

  let(:yesterday) { Time.now.getlocal.prev_day }
  let!(:application) do
    FactoryBot.create(
      :financial_assistance_application,
      submitted_at: yesterday,
      family_id: family.id
    #   eligibility_determinations: eligibility_determinations
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
      encrypted_ssn: person.encrypted_ssn
    #   eligibility_determination_id: eligibility_determination.id
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
      encrypted_ssn: person.encrypted_ssn
    #   eligibility_determination_id: eligibility_determination2.id
    )
  end
  let!(:applicants) { [applicant, applicant2] }

  let(:primary_applicant) { application.applicants.first }
  let(:spouse_applicant) { application.applicants.last }
  let(:field_names) do
    %w[
        primary_hbx_id
        first_name
        last_name
        communication_preference
        primary_email_address
        application_aasm_state
        application_aasm_state_date
        external_id
        user_account
        last_page_visited
        program_eligible_for
      ]
  end

  before :each do
    application.non_primary_applicants.each{|applicant| application.ensure_relationship_with_primary(applicant, applicant.relationship) }
    invoke_applicant_outreach_report
    @file_content = CSV.read("#{Rails.root}/applicant_outreach_report.csv")
  end

  it 'should add data to the file' do
    expect(@file_content.size).to be > 1
  end

  it 'should contain the requested fields' do
    expect(@file_content[0]).to eq(field_names)
  end

  context 'primary person' do
    it 'should match with the primary person hbx id' do
      expect(@file_content[1][0]).to eq(family.primary_person.hbx_id.to_s)
    end

    it 'should match with the primary person first name' do
      expect(@file_content[1][1]).to eq(family.primary_person.first_name)
    end

    it 'should match with the primary person last name' do
      expect(@file_content[1][2]).to eq(family.primary_person.last_name)
    end

    it 'should match with the primary person contact method' do
        binding.irb
      expect(@file_content[1][2]).to eq(family.primary_person.consumer_role.contact_method)
    end
  end


  after :each do
    FileUtils.rm_rf("#{Rails.root}/applicant_outreach_report.csv")
  end
end

def invoke_applicant_outreach_report
  applicant_outreach_report = File.join(Rails.root, "script/applicant_outreach_report.rb")
  load applicant_outreach_report
end
