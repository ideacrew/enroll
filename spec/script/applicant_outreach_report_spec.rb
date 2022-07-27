# frozen_string_literal: true

require 'rails_helper'

describe 'applicant_outreach_report' do
  before do
    DatabaseCleaner.clean
  end

  let!(:user) { FactoryBot.create(:user, person: primary_person, last_portal_visited: DateTime.now)}
  let(:person_dob_year) { Date.today.year - 48 }
  let!(:primary_person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role, :with_mailing_address, dob: Date.new(person_dob_year, 4, 4)) }
  let!(:spouse_person) do
    member = FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role, dob: (primary_person.dob - 10.years))
    primary_person.ensure_relationship_with(member, 'spouse')
    member.save!
    member
  end

  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: primary_person, external_app_id: '12345') }
  let!(:family_member) { family.primary_applicant }
  let!(:family_member2) { FactoryBot.create(:family_member, family: family, person: spouse_person) }
  let!(:hbx_enrollment) { FactoryBot.create(:hbx_enrollment, family: family) }

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
      family_id: family.id,
      aasm_state: 'draft'
    #   eligibility_determinations: eligibility_determinations
    )
  end

  let!(:primary_applicant) do
    FactoryBot.create(
      :financial_assistance_applicant,
      # :with_home_address,
      addresses: primary_person.addresses,
      application: application,
      family_member_id: family_member.id,
      person_hbx_id: primary_person.hbx_id,
      is_primary_applicant: true,
      citizen_status: 'us_citizen',
      is_ia_eligible: true,
      is_medicaid_chip_eligible: false,
      csr_percent_as_integer: 73,
      first_name: primary_person.first_name,
      last_name: primary_person.last_name,
      gender: primary_person.gender,
      dob: primary_person.dob,
      encrypted_ssn: primary_person.encrypted_ssn
    #   eligibility_determination_id: eligibility_determination.id
    )
  end
  let!(:spouse_applicant) do
    FactoryBot.create(
      :financial_assistance_applicant,
      :spouse,
      addresses: [spouse_person.home_address],
      # :with_home_address,
      application: application,
      family_member_id: family_member2.id,
      person_hbx_id: spouse_person.hbx_id,
      citizen_status: 'alien_lawfully_present',
      is_ia_eligible: false,
      is_medicaid_chip_eligible: true,
      csr_percent_as_integer: 87,
      first_name: spouse_person.first_name,
      last_name: spouse_person.last_name,
      gender: spouse_person.gender,
      dob: spouse_person.dob,
      encrypted_ssn: spouse_person.encrypted_ssn
    #   eligibility_determination_id: eligibility_determination2.id
    )
  end
  let!(:applicants) { [primary_applicant, spouse_applicant] }

  # let(:primary_applicant) { application.applicants.first }
  # let(:spouse_applicant) { application.applicants.last }
  let(:field_names) do
    %w[
        primary_hbx_id
        first_name
        last_name
        communication_preference
        primary_email_address
        home_address
        mailing_address
        application_aasm_state
        application_aasm_state_date
        external_id
        user_account
        last_page_visited
        program_eligible_for
        hios_id
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

  context 'applicants' do
    it 'should include all applicants in the report' do
      # minus 1 b/c first row is headers
      expect(@file_content.length - 1).to eq(application.applicants.count)
    end
  end

  context 'primary person' do
    it 'should match with the primary person hbx id' do
      expect(@file_content[1][0]).to eq(primary_person.hbx_id.to_s)
    end

    it 'should match with the primary person first name' do
      expect(@file_content[1][1]).to eq(primary_person.first_name)
    end

    it 'should match with the primary person last name' do
      expect(@file_content[1][2]).to eq(primary_person.last_name)
    end

    it 'should match with the primary person contact method' do
      expect(@file_content[1][3]).to eq(primary_person.consumer_role.contact_method)
    end

    it 'should match with the primary person email address' do
      expect(@file_content[1][4]).to eq(primary_person.work_email_or_best)
    end

    it 'should match with the primary person home address' do
      expect(@file_content[1][5]).to eq(primary_person.home_address.to_s)
    end

    it 'should match with the primary person mailing address' do
      mailing_address = primary_applicant.addresses.where(kind: 'mailing').first
      expect(@file_content[1][6]).to eq(mailing_address.to_s)
    end
  end

  context 'spouse person' do
    it 'should match with the spouse person hbx id' do
      expect(@file_content[2][0]).to eq(spouse_person.hbx_id.to_s)
    end

    it 'should match with the spouse person first name' do
      expect(@file_content[2][1]).to eq(spouse_person.first_name)
    end

    it 'should match with the spouse person last name' do
      expect(@file_content[2][2]).to eq(spouse_person.last_name)
    end

    it 'should match with the spouse person contact method' do
      expect(@file_content[2][3]).to eq(spouse_person.consumer_role.contact_method)
    end

    it 'should match with the spouse person email address' do
      expect(@file_content[2][4]).to eq(spouse_person.work_email_or_best)
    end

    it 'should match with the spouse person home address' do
      expect(@file_content[2][5]).to eq(spouse_applicant.home_address.to_s)
    end

    it 'should match with the spouse person mailing address' do
      mailing_address = spouse_applicant.addresses.where(kind: 'mailing').first
      expect(@file_content[2][6]).to eq(mailing_address.to_s)
    end
  end

  context 'application' do
    it 'should match with the application aasm_state' do
      expect(@file_content[1][7]).to eq(application.aasm_state)
      expect(@file_content[2][7]).to eq(application.aasm_state)
    end

    it 'should match with the date of the most recent aasm_state transition' do
      # how to stub workflow state transition???
      # expect(@file_content[1][8]).to eq(application.workflow_state_transitions.first.transition_at)
    end

    it 'should match with the programs that applicants are eligible for' do
      eligible_programs = "MaineCare and Cub Care(Medicaid),Financial assistance(APTC eligible)"
      expect(@file_content[1][12]).to eq(eligible_programs)
      expect(@file_content[2][12]).to eq(eligible_programs)
    end
  end

  context 'family' do
    it 'should match with the family external app id' do
      expect(@file_content[1][9]).to eq(family.external_app_id)
      expect(@file_content[2][9]).to eq(family.external_app_id)
    end

    context 'plan' do
      it 'should match with the most recent active plan hios id' do
        plan = family.active_household.active_hbx_enrollments.detect {|enr| enr.coverage_kind == 'health'}&.plan
        expect(@file_content[1][13]).to eq(plan&.hios_id)
        expect(@file_content[2][13]).to eq(plan&.hios_id)
      end
    end
  end

  context 'user' do
    it 'should match with the user account email' do
      expect(@file_content[1][10]).to eq(primary_person.user.email)
      expect(@file_content[2][10]).to eq(primary_person.user.email)
    end

    it 'should match with the user account last page visited' do
      expect(@file_content[1][11]).to eq(primary_person.user.last_portal_visited)
      expect(@file_content[2][11]).to eq(primary_person.user.last_portal_visited)
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
