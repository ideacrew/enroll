# frozen_string_literal: true

require 'rails_helper'

describe 'member_outreach_report' do
  before do
    DatabaseCleaner.clean
  end

  let!(:user) { FactoryBot.create(:user, person: primary_person, last_portal_visited: DateTime.now)}
  let(:person_dob_year) { Date.today.year - 48 }
  let!(:primary_person) do
    FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role, :with_mailing_address, dob: Date.new(person_dob_year, 4, 4))
  end
  let!(:spouse_person) do
    member = FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role, dob: (primary_person.dob - 11.years))
    primary_person.ensure_relationship_with(member, 'spouse')
    member.save!
    member
  end
  let!(:no_app_primary_person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role, :with_mailing_address, dob: Date.new(person_dob_year, 4, 4)) }
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: primary_person, external_app_id: '12345') }
  let!(:primary_fm) { family.primary_applicant }
  let!(:spouse_fm) { FactoryBot.create(:family_member, family: family, person: spouse_person) }
  let!(:family_members) { [primary_fm, spouse_fm] }
  let!(:health_enrollment) { FactoryBot.create(:hbx_enrollment, :with_health_product, family: family, effective_on: TimeKeeper.date_of_record.beginning_of_year) }
  let!(:no_app_family) { FactoryBot.create(:family, :with_primary_family_member, person: no_app_primary_person) }
  let!(:no_app_primary_fm) { no_app_family.primary_applicant }
  let!(:no_app_family_members) { [no_app_primary_fm] }
  let(:prospective_year) { TimeKeeper.date_of_record.year + 1 }
  let!(:prospective_year_health_enrollment) { FactoryBot.create(:hbx_enrollment, :with_health_product, family: family, effective_on: Date.new(prospective_year, 1, 1)) }
  let!(:dental_enrollment) { FactoryBot.create(:hbx_enrollment, :with_dental_product, family: family, effective_on: TimeKeeper.date_of_record.beginning_of_year) }
  let!(:prospective_year_dental_enrollment) { FactoryBot.create(:hbx_enrollment, :with_dental_product, family: family, effective_on: Date.new(prospective_year, 1, 1)) }
  let!(:enrollment_members) do
    family_members.map do |member|
      FactoryBot.build(:hbx_enrollment_member, applicant_id: member.id, hbx_enrollment: health_enrollment, is_subscriber: member.is_primary_applicant)
    end
  end
  let(:yesterday) { Time.now.getlocal.prev_day }
  let!(:latest_determined_application) do
    FactoryBot.create(
      :financial_assistance_application,
      applicants: applicants,
      submitted_at: yesterday,
      family_id: family.id,
      aasm_state: 'determined',
      transfer_id: 'tr12345',
      assistance_year: FinancialAssistance::Operations::EnrollmentDates::ApplicationYear.new.call.value!,
      transferred_at: DateTime.now
    )
  end
  let!(:latest_application) do
    FactoryBot.create(
      :financial_assistance_application,
      applicants: applicants,
      submitted_at: yesterday,
      family_id: family.id,
      aasm_state: 'draft',
      transfer_id: 'tr12345',
      assistance_year: FinancialAssistance::Operations::EnrollmentDates::ApplicationYear.new.call.value!,
      transferred_at: DateTime.now
    )
  end
  let(:primary_applicant) do
    FactoryBot.create(
      :financial_assistance_applicant,
      benefits: [benefit],
      # application: application,
      family_member_id: primary_fm.id,
      person_hbx_id: primary_person.hbx_id,
      is_primary_applicant: true,
      citizen_status: 'us_citizen',
      is_without_assistance: true,
      csr_percent_as_integer: 73,
      first_name: primary_person.first_name,
      last_name: primary_person.last_name,
      gender: primary_person.gender,
      dob: primary_person.dob,
      encrypted_ssn: primary_person.encrypted_ssn,
      has_eligible_health_coverage: true
    )
  end
  let(:spouse_applicant) do
    FactoryBot.create(
      :financial_assistance_applicant,
      :spouse,
      # application: application,
      family_member_id: spouse_fm.id,
      person_hbx_id: spouse_person.hbx_id,
      citizen_status: 'alien_lawfully_present',
      is_medicaid_chip_eligible: true,
      csr_percent_as_integer: 87,
      first_name: spouse_person.first_name,
      last_name: spouse_person.last_name,
      gender: spouse_person.gender,
      dob: spouse_person.dob,
      encrypted_ssn: spouse_person.encrypted_ssn,
      has_eligible_health_coverage: false
    )
  end
  let(:applicants) { [primary_applicant, spouse_applicant] }
  let!(:workflow_state_transition) { WorkflowStateTransition.new(to_state: 'draft', transition_at: Time.now) }
  let(:benefit) { FactoryBot.build(:financial_assistance_benefit) }
  let(:curr_year) { TimeKeeper.date_of_record.year }
  let(:next_year) { TimeKeeper.date_of_record.year + 1 }
  let(:field_names) do
    headers = %w[
        subscriber_hbx_id
        member_hbx_id
        subscriber_indicator
        first_name
        last_name
        dob
        communication_preference
        primary_email_address
        home_address
        mailing_address
        home_phone
        work_phone
        mobile_phone
        external_id
        user_account
        last_page_visited
        latest_determined_application_id
        determined_date
        determined_program_eligible_for
        determined_medicaid_fpl
        determined_has_access_to_coverage
        determined_has_access_to_coverage_kinds
        latest_application_aasm_state
        latest_application_aasm_state_date
        latest_transfer_id
        inbound_transfer_date
      ]
    headers << "#{curr_year}_most_recent_health_plan_id"
    headers << "#{curr_year}_most_recent_health_status"
    headers << "#{next_year}_most_recent_health_plan_id"
    headers << "#{next_year}_most_recent_health_status"
    headers << "#{curr_year}_most_recent_dental_plan_id"
    headers << "#{curr_year}_most_recent_dental_status"
    headers << "#{next_year}_most_recent_dental_plan_id"
    headers << "#{next_year}_most_recent_dental_status"
  end

  context 'family with application in current enrollment year' do
    before do
      latest_application.non_primary_applicants.each{|applicant| latest_application.ensure_relationship_with_primary(applicant, applicant.relationship) }
      latest_determined_application.non_primary_applicants.each{|applicant| latest_determined_application.ensure_relationship_with_primary(applicant, applicant.relationship) }
      latest_application.update(workflow_state_transitions: [workflow_state_transition])
      latest_determined_application.update(workflow_state_transitions: [workflow_state_transition])
      health_enrollment.update(hbx_enrollment_members: enrollment_members)
      invoke_member_outreach_report
      @file_content = CSV.read("#{Rails.root}/member_outreach_report.csv")
    end

    it 'should add data to the file' do
      expect(@file_content.size).to be > 1
    end

    it 'should contain the requested fields' do
      expect(@file_content[0]).to eq(field_names)
    end

    context 'family members' do
      it 'should include all family members in the report' do
        # minus 1 b/c first row is headers
        members_count = family_members.count + no_app_family_members.count
        expect(@file_content.length - 1).to eq(members_count)
      end
    end

    context 'primary person' do
      it 'should match with the primary person hbx id' do
        expect(@file_content[1][1]).to eq(primary_person.hbx_id.to_s)
      end

      it 'should match with the primary person first name' do
        expect(@file_content[1][3]).to eq(primary_person.first_name)
      end

      it 'should match with the primary person last name' do
        expect(@file_content[1][4]).to eq(primary_person.last_name)
      end

      it 'should match with the primary person dob' do
        expect(@file_content[1][5]).to eq(primary_person.dob.to_s)
      end

      it 'should match with the primary person contact method' do
        expect(@file_content[1][6]).to eq(primary_person.consumer_role.contact_method)
      end

      it 'should match with the primary person email address' do
        expect(@file_content[1][7]).to eq(primary_person.work_email_or_best)
      end

      it 'should match with the primary person home address' do
        expect(@file_content[1][8]).to eq(primary_person.home_address.to_s)
      end

      it 'should match with the primary person mailing address' do
        mailing_address = primary_person.addresses.where(kind: 'mailing').first
        expect(@file_content[1][9]).to eq(mailing_address.to_s)
      end

      it 'should match with the primary person home phone' do
        home_phone = primary_person.phones.detect{|p| p.kind == 'home'}
        expect(@file_content[1][10]).to eq(home_phone.to_s)
      end

      it 'should match with the primary person work phone' do
        work_phone = primary_person.phones.detect{|p| p.kind == 'work'}
        expect(@file_content[1][11]).to eq(work_phone.to_s)
      end

      it 'should match with the primary person mobile phone' do
        mobile_phone = primary_person.phones.detect{|p| p.kind == 'mobile'}
        expect(@file_content[1][12]).to eq(mobile_phone.to_s)
      end
    end

    context 'primary applicant' do
      it 'should match with the applicant access to health coverage response' do
        expect(@file_content[1][20]).to eq(primary_applicant.has_eligible_health_coverage.present?.to_s)
      end

      it 'should match with the health coverage kinds applicant has access to' do
        insurance_kinds = primary_applicant.benefits.eligible.map(&:insurance_kind).join(", ")
        expect(@file_content[1][21]).to eq(insurance_kinds)
      end
    end

    context 'spouse person' do
      it 'should match with the spouse person hbx id' do
        expect(@file_content[2][1]).to eq(spouse_person.hbx_id.to_s)
      end

      it 'should match with the spouse person first name' do
        expect(@file_content[2][3]).to eq(spouse_person.first_name)
      end

      it 'should match with the spouse person last name' do
        expect(@file_content[2][4]).to eq(spouse_person.last_name)
      end

      it 'should match with the spouse person dob' do
        expect(@file_content[2][5]).to eq(spouse_person.dob.to_s)
      end

      it 'should match with the spouse person contact method' do
        expect(@file_content[2][6]).to eq(spouse_person.consumer_role.contact_method)
      end

      it 'should match with the spouse person email address' do
        expect(@file_content[2][7]).to eq(spouse_person.work_email_or_best)
      end

      it 'should match with the spouse person home address' do
        expect(@file_content[2][8]).to eq(spouse_person.home_address.to_s)
      end

      it 'should match with the spouse person mailing address' do
        mailing_address = spouse_person.mailing_address
        expect(@file_content[2][9]).to eq(mailing_address.to_s)
      end

      it 'should match with the spouse person home phone' do
        home_phone = spouse_person.phones.detect{|p| p.kind == 'home'}
        expect(@file_content[2][10]).to eq(home_phone.to_s)
      end

      it 'should match with the spouse person work phone' do
        work_phone = spouse_person.phones.detect{|p| p.kind == 'work'}
        expect(@file_content[2][11]).to eq(work_phone.to_s)
      end

      it 'should match with the spouse person mobile phone' do
        mobile_phone = spouse_person.phones.detect{|p| p.kind == 'mobile'}
        expect(@file_content[2][12]).to eq(mobile_phone.to_s)
      end
    end

    context 'spouse applicant' do
      it 'should match with the applicant access to health coverage response' do
        expect(@file_content[2][20]).to eq(spouse_applicant.has_eligible_health_coverage.present?.to_s)
      end

      it 'should match with the health coverage kinds applicant has access to' do
        insurance_kinds = spouse_applicant.benefits.eligible.map(&:insurance_kind).join(", ")
        expect(@file_content[2][21]).to eq(insurance_kinds)
      end
    end

    context 'latest determined application' do
      it 'should match with application id' do
        expect(@file_content[1][16]).to eq(latest_determined_application.hbx_id)
        expect(@file_content[2][16]).to eq(latest_determined_application.hbx_id)
      end

      it 'should match with the determination date' do
        expect(@file_content[1][17]).to eq(latest_determined_application.submitted_at.to_s)
        expect(@file_content[2][17]).to eq(latest_determined_application.submitted_at.to_s)
      end

      it 'should match with the programs that the applicants are eligible for' do
        primary_eligible_programs = "QHP without financial assistance"
        spouse_eligible_programs = "MaineCare and Cub Care(Medicaid)"
        expect(@file_content[1][18]).to eq(primary_eligible_programs)
        expect(@file_content[2][18]).to eq(spouse_eligible_programs)
      end
    end

    context 'latest application (in any submission state)' do
      it 'should match with the application aasm_state' do
        expect(@file_content[1][22]).to eq(latest_application.aasm_state)
        expect(@file_content[2][22]).to eq(latest_application.aasm_state)
      end

      it 'should match with the date of the most recent aasm_state transition' do
        expect(@file_content[1][23]).to eq(latest_application.workflow_state_transitions.first.transition_at.to_s)
        expect(@file_content[2][23]).to eq(latest_application.workflow_state_transitions.first.transition_at.to_s)
      end

      it 'should match with the transfer id' do
        expect(@file_content[1][24]).to eq(latest_application.transfer_id)
        expect(@file_content[2][24]).to eq(latest_application.transfer_id)
      end

      it 'should match with the inbound transfer timestamp' do
        transfer_timestamp = latest_application.transferred_at
        expect(@file_content[1][25]).to eq(transfer_timestamp.to_s)
        expect(@file_content[2][25]).to eq(transfer_timestamp.to_s)
      end
    end

    context 'family' do
      it 'should match with the family external app id' do
        expect(@file_content[1][13]).to eq(family.external_app_id)
        expect(@file_content[2][13]).to eq(family.external_app_id)
      end

      context 'plan' do
        before do
          @enrollments = family.active_household.hbx_enrollments
        end

        it 'should match with health plan subscriber hbx id' do
          expect(@file_content[1][0]).to eq(primary_person.hbx_id.to_s)
          expect(@file_content[2][0]).to eq(primary_person.hbx_id.to_s)
        end

        it 'should match with the current year most recent health plan hios id' do
          health_enrollment = @enrollments.select {|enr| enr.coverage_kind == 'health' && enr.effective_on.year == curr_year}.sort_by(&:submitted_at).reverse.first
          expect(@file_content[1][26]).to eq(health_enrollment.product.hios_id)
          expect(@file_content[2][26]).to eq(health_enrollment.product.hios_id)
        end

        it 'should match with the current year most recent health plan status' do
          health_enrollment = @enrollments.select {|enr| enr.coverage_kind == 'health' && enr.effective_on.year == curr_year}.sort_by(&:submitted_at).reverse.first
          expect(@file_content[1][27]).to eq(health_enrollment.aasm_state)
          expect(@file_content[2][27]).to eq(health_enrollment.aasm_state)
        end

        it 'should match with the prospective year most recent health plan hios id' do
          health_enrollment = @enrollments.select {|enr| enr.coverage_kind == 'health' && enr.effective_on.year == next_year}.sort_by(&:submitted_at).reverse.first
          expect(@file_content[1][28]).to eq(health_enrollment.product.hios_id)
          expect(@file_content[2][28]).to eq(health_enrollment.product.hios_id)
        end

        it 'should match with the prospective year most recent health plan status' do
          health_enrollment = @enrollments.select {|enr| enr.coverage_kind == 'health' && enr.effective_on.year == next_year}.sort_by(&:submitted_at).reverse.first
          expect(@file_content[1][29]).to eq(health_enrollment.aasm_state)
          expect(@file_content[2][29]).to eq(health_enrollment.aasm_state)
        end

        it 'should match with the current year most recent dental plan hios id' do
          dental_enrollment = @enrollments.select {|enr| enr.coverage_kind == 'dental' && enr.effective_on.year == curr_year}.sort_by(&:submitted_at).reverse.first
          expect(@file_content[1][30]).to eq(dental_enrollment.product.hios_id)
          expect(@file_content[2][30]).to eq(dental_enrollment.product.hios_id)
        end

        it 'should match with the current year most recent dental plan status' do
          dental_enrollment = @enrollments.select {|enr| enr.coverage_kind == 'dental' && enr.effective_on.year == curr_year}.sort_by(&:submitted_at).reverse.first
          expect(@file_content[1][31]).to eq(dental_enrollment.aasm_state)
          expect(@file_content[2][31]).to eq(dental_enrollment.aasm_state)
        end

        it 'should match with the prospective year most recent dental plan hios id' do
          dental_enrollment = @enrollments.select {|enr| enr.coverage_kind == 'dental' && enr.effective_on.year == next_year}.sort_by(&:submitted_at).reverse.first
          expect(@file_content[1][32]).to eq(dental_enrollment.product.hios_id)
          expect(@file_content[2][32]).to eq(dental_enrollment.product.hios_id)
        end

        it 'should match with the prospective year most recent dental plan status' do
          dental_enrollment = @enrollments.select {|enr| enr.coverage_kind == 'dental' && enr.effective_on.year == next_year}.sort_by(&:submitted_at).reverse.first
          expect(@file_content[1][33]).to eq(dental_enrollment.aasm_state)
          expect(@file_content[2][33]).to eq(dental_enrollment.aasm_state)
        end
      end
    end

    context 'user' do
      it 'should match with the user account email' do
        expect(@file_content[1][14]).to eq(primary_person.user.email)
        expect(@file_content[2][14]).to eq(primary_person.user.email)
      end

      it 'should match with the u5er account last page visited' do
        expect(@file_content[1][15]).to eq(primary_person.user.last_portal_visited)
        expect(@file_content[2][15]).to eq(primary_person.user.last_portal_visited)
      end
    end

    context 'hbx enrollment member' do
      it 'should match with the subscriber indicator' do
        expect(@file_content[1][2]).to eq("false")
        expect(@file_content[2][2]).to eq("false")
      end
    end
  end

  context 'enrollment is terminated or canceled' do
    before do
      health_enrollment.update(aasm_state: 'coverage_terminated')
      dental_enrollment.update(aasm_state: 'coverage_canceled')
      latest_application.non_primary_applicants.each{|applicant| latest_application.ensure_relationship_with_primary(applicant, applicant.relationship) }
      latest_determined_application.non_primary_applicants.each{|applicant| latest_determined_application.ensure_relationship_with_primary(applicant, applicant.relationship) }
      latest_application.update(workflow_state_transitions: [workflow_state_transition])
      latest_determined_application.update(workflow_state_transitions: [workflow_state_transition])
      health_enrollment.update(hbx_enrollment_members: enrollment_members)
      invoke_member_outreach_report
      @file_content = CSV.read("#{Rails.root}/member_outreach_report.csv")
      @enrollments = family.active_household.hbx_enrollments
    end

    context 'for the terminated enrollment data' do
      it 'should match with the current year most recent health plan hios id' do
        health_enrollment = @enrollments.select {|enr| enr.coverage_kind == 'health' && enr.effective_on.year == curr_year}.sort_by(&:submitted_at).reverse.first
        expect(@file_content[1][26]).to eq(health_enrollment.product.hios_id)
        expect(@file_content[2][26]).to eq(health_enrollment.product.hios_id)
      end

      it 'should match with the current year most recent health plan status' do
        health_enrollment = @enrollments.select {|enr| enr.coverage_kind == 'health' && enr.effective_on.year == curr_year}.sort_by(&:submitted_at).reverse.first
        expect(@file_content[1][27]).to eq(health_enrollment.aasm_state)
        expect(@file_content[2][27]).to eq(health_enrollment.aasm_state)
      end

      it 'should match with the prospective year most recent health plan hios id' do
        health_enrollment = @enrollments.select {|enr| enr.coverage_kind == 'health' && enr.effective_on.year == next_year}.sort_by(&:submitted_at).reverse.first
        expect(@file_content[1][28]).to eq(health_enrollment.product.hios_id)
        expect(@file_content[2][28]).to eq(health_enrollment.product.hios_id)
      end

      it 'should match with the prospective year most recent health plan status' do
        health_enrollment = @enrollments.select {|enr| enr.coverage_kind == 'health' && enr.effective_on.year == next_year}.sort_by(&:submitted_at).reverse.first
        expect(@file_content[1][29]).to eq(health_enrollment.aasm_state)
        expect(@file_content[2][29]).to eq(health_enrollment.aasm_state)
      end
    end

    context 'for the cancelled enrollment data' do
      it 'should match with the current year most recent dental plan hios id' do
        dental_enrollment = @enrollments.select {|enr| enr.coverage_kind == 'dental' && enr.effective_on.year == curr_year}.sort_by(&:submitted_at).reverse.first
        expect(@file_content[1][30]).to eq(dental_enrollment.product.hios_id)
        expect(@file_content[2][30]).to eq(dental_enrollment.product.hios_id)
      end

      it 'should match with the current year most recent dental plan status' do
        dental_enrollment = @enrollments.select {|enr| enr.coverage_kind == 'dental' && enr.effective_on.year == curr_year}.sort_by(&:submitted_at).reverse.first
        expect(@file_content[1][31]).to eq(dental_enrollment.aasm_state)
        expect(@file_content[2][31]).to eq(dental_enrollment.aasm_state)
      end

      it 'should match with the prospective year most recent dental plan hios id' do
        dental_enrollment = @enrollments.select {|enr| enr.coverage_kind == 'dental' && enr.effective_on.year == next_year}.sort_by(&:submitted_at).reverse.first
        expect(@file_content[1][32]).to eq(dental_enrollment.product.hios_id)
        expect(@file_content[2][32]).to eq(dental_enrollment.product.hios_id)
      end

      it 'should match with the prospective year most recent dental plan status' do
        dental_enrollment = @enrollments.select {|enr| enr.coverage_kind == 'dental' && enr.effective_on.year == next_year}.sort_by(&:submitted_at).reverse.first
        expect(@file_content[1][33]).to eq(dental_enrollment.aasm_state)
        expect(@file_content[2][33]).to eq(dental_enrollment.aasm_state)
      end
    end
  end

  after :each do
    FileUtils.rm_rf("#{Rails.root}/member_outreach_report.csv")
  end
end

def invoke_member_outreach_report
  member_outreach_report = File.join(Rails.root, "script/member_outreach_report.rb")
  load member_outreach_report
end
