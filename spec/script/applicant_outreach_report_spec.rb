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
  let!(:primary_fm) { family.primary_applicant }
  let!(:spouse_fm) { FactoryBot.create(:family_member, family: family, person: spouse_person) }
  let!(:family_members) { [primary_fm, spouse_fm] }
  let!(:health_enrollment) { FactoryBot.create(:hbx_enrollment, family: family) }
  let!(:dental_enrollment) { FactoryBot.create(:hbx_enrollment, :with_dental_coverage_kind, family: family) }
  let!(:enrollment_members) do
    family_members.map do |member|
      FactoryBot.build(:hbx_enrollment_member, applicant_id: member.id, hbx_enrollment: health_enrollment, is_subscriber: member.is_primary_applicant)
    end
  end
  let(:yesterday) { Time.now.getlocal.prev_day }
  let!(:application) do
    FactoryBot.create(
      :financial_assistance_application,
      submitted_at: yesterday,
      family_id: family.id,
      aasm_state: 'draft',
      transfer_id: 'tr12345'
    )
  end
  let!(:primary_applicant) do
    FactoryBot.create(
      :financial_assistance_applicant,
      addresses: primary_person.addresses,
      application: application,
      family_member_id: primary_fm.id,
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
    )
  end
  let!(:spouse_applicant) do
    FactoryBot.create(
      :financial_assistance_applicant,
      :spouse,
      addresses: [spouse_person.home_address],
      application: application,
      family_member_id: spouse_fm.id,
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
    )
  end
  let(:applicants) { [primary_applicant, spouse_applicant] }
  let!(:workflow_state_transition) { WorkflowStateTransition.new(to_state: 'draft', transition_at: Time.now) }
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
        health_plan_hios_id
        dental_plan_id
        subscriber_indicator
        transfer_id
      ]
  end

  before :each do
    application.non_primary_applicants.each{|applicant| application.ensure_relationship_with_primary(applicant, applicant.relationship) }
    application.update(workflow_state_transitions: [workflow_state_transition])
    health_enrollment.update(hbx_enrollment_members: enrollment_members)
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
      expect(@file_content[1][8]).to eq(application.workflow_state_transitions.first.transition_at.to_s)
    end

    it 'should match with the programs that applicants are eligible for' do
      eligible_programs = "MaineCare and Cub Care(Medicaid),Financial assistance(APTC eligible)"
      expect(@file_content[1][12]).to eq(eligible_programs)
      expect(@file_content[2][12]).to eq(eligible_programs)
    end

    it 'should match with the transfer id' do
      expect(@file_content[1][16]).to eq(application.transfer_id)
      expect(@file_content[2][16]).to eq(application.transfer_id)
    end
  end

  context 'family' do
    it 'should match with the family external app id' do
      expect(@file_content[1][9]).to eq(family.external_app_id)
      expect(@file_content[2][9]).to eq(family.external_app_id)
    end

    context 'plan' do
      it 'should match with the most recent active health plan hios id' do
        health_plan = family.active_household.active_hbx_enrollments.detect {|enr| enr.coverage_kind == 'health'}&.plan
        expect(@file_content[1][13]).to eq(health_plan&.hios_id)
        expect(@file_content[2][13]).to eq(health_plan&.hios_id)
      end

      it 'should match with the most recent active dental plan id' do
        dental_plan = family.active_household.active_hbx_enrollments.detect {|enr| enr.coverage_kind == 'dental'}&.plan
        expect(@file_content[1][14]).to eq(dental_plan&.hios_id)
        expect(@file_content[2][14]).to eq(dental_plan&.hios_id)
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

  context 'hbx enrollment member' do
    it 'should match with the subscriber indicator' do
      health_enrollment = family.active_household.active_hbx_enrollments.detect {|enr| enr.coverage_kind == 'health'}
      primary_member = health_enrollment&.hbx_enrollment_members&.detect {|member| member.applicant_id == primary_fm.id}
      spouse_member = health_enrollment&.hbx_enrollment_members&.detect {|member| member.applicant_id == spouse_fm.id}
      expect(@file_content[1][15]).to eq(primary_member.is_subscriber.to_s)
      expect(@file_content[2][15]).to eq(spouse_member.is_subscriber.to_s)
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
