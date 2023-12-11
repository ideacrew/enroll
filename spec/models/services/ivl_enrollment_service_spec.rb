# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Services::IvlEnrollmentService, type: :model, :dbclean => :after_each do

  let(:person) { FactoryBot.create(:person, :with_consumer_role)}
  let!(:family) {FactoryBot.create(:family, :with_primary_family_member, person: person, e_case_id: nil)}
  let(:created_at) { TimeKeeper.date_of_record.to_datetime }
  let!(:hbx_enrollment) do
    create(
      :hbx_enrollment,
      family: family,
      household: family.households.first,
      kind: "individual",
      is_any_enrollment_member_outstanding: true,
      aasm_state: "coverage_selected",
      applied_aptc_amount: 0.0,
      created_at: created_at
    )
  end
  let!(:hbx_enrollment_member) {FactoryBot.create(:hbx_enrollment_member,hbx_enrollment: hbx_enrollment, applicant_id: family.family_members.first.id, is_subscriber: true, eligibility_date: TimeKeeper.date_of_record.prev_month)}

  subject do
    Services::IvlEnrollmentService.new
  end

  before do
    allow(EnrollRegistry).to receive(:feature_enabled?).and_call_original
    allow(EnrollRegistry).to receive(:feature_enabled?).with(:async_expire_and_begin_coverages).and_return(false)
  end

  context "send_reminder_notices_for_ivl" do

    context 'when include_faa_outstanding_verifications feature is turned off' do
      before :each do
        allow(EnrollRegistry[:legacy_enrollment_trigger].feature).to receive(:is_enabled).and_return(true)
      end

      it 'should trigger first reminder notice for unassisted families after 10 days of ENR notice' do
        person.verification_types.each{|type| type.fail_type && type.update_attributes(due_date: TimeKeeper.date_of_record + 85.days)}
        family.update_attributes(min_verification_due_date: TimeKeeper.date_of_record + 85.days)
        person.consumer_role.update_attributes!(aasm_state: "verification_outstanding")
        hbx_enrollment.save!
        expect(IvlNoticesNotifierJob).to receive(:perform_later)
        subject.send_reminder_notices_for_ivl(TimeKeeper.date_of_record)
      end

      it 'should not trigger first reminder notice for unassisted families before 10 days of ENR notice' do
        person.verification_types.each{|type| type.fail_type && type.update_attributes(due_date: TimeKeeper.date_of_record + 88.days)}
        family.update_attributes(min_verification_due_date: TimeKeeper.date_of_record + 88.days)
        person.consumer_role.update_attributes!(aasm_state: "verification_outstanding")
        hbx_enrollment.save!
        expect(IvlNoticesNotifierJob).not_to receive(:perform_later)
        subject.send_reminder_notices_for_ivl(TimeKeeper.date_of_record)
      end

      context 'when consumer is assisted' do
        context 'when skip_aptc_families_from_document_reminder_notices feature is turned on' do
          before do
            allow(EnrollRegistry[:skip_aptc_families_from_document_reminder_notices].feature).to receive(:is_enabled).and_return(true)
          end

          it 'should not trigger reminder notice for families from curam' do
            family.update_attributes!(:e_case_id => "someecaseid")
            person.consumer_role.update_attributes!(aasm_state: "verification_outstanding")
            hbx_enrollment.save!
            expect(IvlNoticesNotifierJob).not_to receive(:perform_later)
            subject.send_reminder_notices_for_ivl(TimeKeeper.date_of_record)
          end
        end

        context 'when skip_aptc_families_from_document_reminder_notices feature is turned off' do
          let(:due_date) { TimeKeeper.date_of_record + 85.days }

          before do
            allow(EnrollRegistry[:legacy_enrollment_trigger].feature).to receive(:is_enabled).and_return(true)
            allow(EnrollRegistry[:skip_aptc_families_from_document_reminder_notices].feature).to receive(:is_enabled).and_return(false)
          end

          it 'should trigger reminder notice for families from curam' do
            person.verification_types.each{|type| type.fail_type && type.update_attributes(due_date: due_date)}
            family.update_attributes!(e_case_id: "someecaseid", min_verification_due_date: due_date)
            person.consumer_role.update_attributes!(aasm_state: "verification_outstanding")
            hbx_enrollment.save!
            expect(IvlNoticesNotifierJob).to receive(:perform_later)
            subject.send_reminder_notices_for_ivl(TimeKeeper.date_of_record)
          end
        end
      end

      it 'should not trigger reminder notice for unassisted families with verified consumers' do
        person.consumer_role.update_attributes!(aasm_state: "fully_verified")
        hbx_enrollment.save!
        expect(IvlNoticesNotifierJob).not_to receive(:perform_later)
        subject.send_reminder_notices_for_ivl(TimeKeeper.date_of_record)
      end

      context 'when document_reminder_notice_trigger is disabled' do
        before do
          allow(EnrollRegistry[:legacy_enrollment_trigger].feature).to receive(:is_enabled).and_return(false)
          allow(EnrollRegistry[:document_reminder_notice_trigger].feature).to receive(:is_enabled).and_return(false)
        end

        it 'should not trigger document reminder events to polypress' do
          person.verification_types.each{|type| type.fail_type && type.update_attributes(due_date: TimeKeeper.date_of_record + 85.days)}
          family.update_attributes(min_verification_due_date: TimeKeeper.date_of_record + 85.days)
          person.consumer_role.update_attributes!(aasm_state: "verification_outstanding")
          hbx_enrollment.save!
          # expect(::Operations::Notices::IvlDocumentReminderNotice).not_to receive(:new)
          subject.send_reminder_notices_for_ivl(TimeKeeper.date_of_record)
        end
      end

      context 'when document_reminder_notice_trigger is enabled' do
        before do
          allow(EnrollRegistry[:legacy_enrollment_trigger].feature).to receive(:is_enabled).and_return(false)
          allow(EnrollRegistry[:document_reminder_notice_trigger].feature).to receive(:is_enabled).and_return(true)
        end

        it 'should trigger document reminder events to polypress' do
          person.verification_types.each{|type| type.fail_type && type.update_attributes(due_date: TimeKeeper.date_of_record + 85.days)}
          family.update_attributes(min_verification_due_date: TimeKeeper.date_of_record + 85.days)
          person.consumer_role.update_attributes!(aasm_state: "verification_outstanding")
          hbx_enrollment.save!
          # expect(::Operations::Notices::IvlDocumentReminderNotice).to receive(:new)
          subject.send_reminder_notices_for_ivl(TimeKeeper.date_of_record)
        end
      end
    end

    context 'when include_faa_outstanding_verifications feature is turned on' do
      let!(:application) do
        create(
          :financial_assistance_application,
          family_id: family.id,
          aasm_state: 'determined',
          hbx_id: "830293",
          assistance_year: TimeKeeper.date_of_record.year
        )
      end
      let!(:applicant) do
        create(
          :applicant,
          first_name: person.first_name,
          last_name: person.last_name,
          dob: person.dob,
          gender: person.gender,
          ssn: person.ssn,
          application: application,
          ethnicity: [],
          is_ia_eligible: true,
          is_primary_applicant: true,
          person_hbx_id: person.hbx_id,
          non_esi_evidence: evidence
        )
      end

      let(:due_on) { TimeKeeper.date_of_record + 85.days }

      let(:evidence) { ::Eligibilities::Evidence.new(key: :non_esi_mec, title: "NON ESI MEC", aasm_state: "outstanding", due_on: due_on) }

      before do
        allow(EnrollRegistry[:legacy_enrollment_trigger].feature).to receive(:is_enabled).and_return(false)
        allow(EnrollRegistry[:document_reminder_notice_trigger].feature).to receive(:is_enabled).and_return(true)
        allow(EnrollRegistry[:include_faa_outstanding_verifications].feature).to receive(:is_enabled).and_return(true)
        allow(EnrollRegistry[:skip_aptc_families_from_document_reminder_notices].feature).to receive(:is_enabled).and_return(false)
        family.update_attributes(min_verification_due_date: due_on)
        person.consumer_role.update_attributes!(aasm_state: "verification_outstanding")
        hbx_enrollment.save!
      end

      it 'should trigger DR notices to families with outstanding evidences' do
        # expect(::Operations::Notices::IvlDocumentReminderNotice).to receive_message_chain('new.call').with(family: family)
        subject.send_reminder_notices_for_ivl(TimeKeeper.date_of_record)
      end
    end
  end

  context ".expire_individual_market_enrollments" do
    let!(:hbx_profile) { FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period)}
    let!(:cover_coverage_enrolled_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        effective_on: Date.new(TimeKeeper.date_of_record.year - 1, 1, 1),
                        household: family.households.first,
                        kind: "coverall",
                        is_any_enrollment_member_outstanding: true,
                        aasm_state: "coverage_selected",
                        applied_aptc_amount: 0.0)
    end

    let!(:cover_coverage_enrolled_enrollment1) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        effective_on: Date.new(TimeKeeper.date_of_record.year - 1, 1, 1),
                        household: family.households.first,
                        kind: "coverall",
                        is_any_enrollment_member_outstanding: true,
                        aasm_state: "coverage_selected",
                        applied_aptc_amount: 0.0)
    end

    it "should expire the cover all coverage_selected enrollment" do
      subject.expire_individual_market_enrollments(TimeKeeper.date_of_record)
      expect(cover_coverage_enrolled_enrollment.reload.aasm_state).to eq "coverage_expired"
      expect(cover_coverage_enrolled_enrollment.workflow_state_transitions.first.event).to eq "expire_coverage!"
    end

    it "should not break when there is an error with one of the enrollments." do
      cover_coverage_enrolled_enrollment.unset(:family_id)
      cover_coverage_enrolled_enrollment.reload
      subject.expire_individual_market_enrollments(TimeKeeper.date_of_record)
      expect(cover_coverage_enrolled_enrollment1.reload.aasm_state).to eq "coverage_expired"
      expect(cover_coverage_enrolled_enrollment1.workflow_state_transitions.first.event).to eq "expire_coverage!"
    end

    context 'when async_expire_and_begin_coverages feature is enabled' do
      before do
        allow(EnrollRegistry).to receive(:feature_enabled?).and_call_original
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:async_expire_and_begin_coverages).and_return(true)
      end

      context 'when input date is not beginning of the year' do
        let(:input_date) { Date.new(TimeKeeper.date_of_record.year, 2, 1) }

        it 'executes without raising any errors' do
          expect{ subject.expire_individual_market_enrollments(input_date) }.not_to raise_error
        end
      end

      context 'when input date is beginning of the year' do
        let(:input_date) { Date.new(TimeKeeper.date_of_record.year) }

        it 'executes without raising any errors' do
          expect{ subject.expire_individual_market_enrollments(input_date) }.not_to raise_error
        end
      end
    end
  end

  context ".begin_coverage_for_ivl_enrollments" do
    let!(:hbx_profile) { FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period)}
    let!(:renewing_selected_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        effective_on: Date.new(TimeKeeper.date_of_record.year, 1, 1),
                        household: family.households.first,
                        kind: "individual",
                        is_any_enrollment_member_outstanding: true,
                        aasm_state: "renewing_coverage_selected",
                        applied_aptc_amount: 0.0)
    end

    let!(:renewing_selected_enrollment_2) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        effective_on: Date.new(TimeKeeper.date_of_record.year, 2, 1),
                        household: family.households.first,
                        kind: "individual",
                        is_any_enrollment_member_outstanding: true,
                        aasm_state: "renewing_coverage_selected",
                        applied_aptc_amount: 0.0)
    end

    let!(:renewing_selected_enrollment_3) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        effective_on: Date.new(TimeKeeper.date_of_record.year, 3, 1),
                        household: family.households.first,
                        kind: "individual",
                        is_any_enrollment_member_outstanding: true,
                        aasm_state: "renewing_coverage_selected",
                        applied_aptc_amount: 0.0)
    end

    let!(:future_renewing_selected_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        effective_on: Date.new(TimeKeeper.date_of_record.year + 1.year, 1, 1),
                        household: family.households.first,
                        kind: "individual",
                        is_any_enrollment_member_outstanding: true,
                        aasm_state: "renewing_coverage_selected",
                        applied_aptc_amount: 0.0)
    end

    let!(:auto_renewing_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        effective_on: Date.new(TimeKeeper.date_of_record.year, 1, 1),
                        household: family.households.first,
                        kind: "individual",
                        is_any_enrollment_member_outstanding: true,
                        aasm_state: "auto_renewing",
                        applied_aptc_amount: 0.0)
    end

    let!(:cover_auto_renewing_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        effective_on: Date.new(TimeKeeper.date_of_record.year, 1, 1),
                        household: family.households.first,
                        kind: "coverall",
                        is_any_enrollment_member_outstanding: true,
                        aasm_state: "auto_renewing",
                        applied_aptc_amount: 0.0)
    end

    it "should picks up the renewing_coverage_selected enrollment" do
      subject.begin_coverage_for_ivl_enrollments
      expect(renewing_selected_enrollment.reload.aasm_state).to eq "coverage_selected"
      expect(renewing_selected_enrollment.workflow_state_transitions.first.event).to eq "begin_coverage!"
    end

    it "should picks up the 2/1 renewing_coverage_selected enrollment" do
      subject.begin_coverage_for_ivl_enrollments
      expect(renewing_selected_enrollment_2.reload.aasm_state).to eq "coverage_selected"
      expect(renewing_selected_enrollment_2.workflow_state_transitions.first.event).to eq "begin_coverage!"
    end

    it "should picks up the 3/1 renewing_coverage_selected enrollment" do
      subject.begin_coverage_for_ivl_enrollments
      expect(renewing_selected_enrollment_3.reload.aasm_state).to eq "coverage_selected"
      expect(renewing_selected_enrollment_3.workflow_state_transitions.first.event).to eq "begin_coverage!"
    end

    it "should not transition the future_renewing_coverage_selected enrollment" do
      subject.begin_coverage_for_ivl_enrollments
      expect(future_renewing_selected_enrollment.reload.aasm_state).to eq "renewing_coverage_selected"
      expect(future_renewing_selected_enrollment.workflow_state_transitions).to be_empty
    end

    it "should picks up the auto renewing enrollment" do
      subject.begin_coverage_for_ivl_enrollments
      expect(auto_renewing_enrollment.reload.aasm_state).to eq "coverage_selected"
      expect(auto_renewing_enrollment.workflow_state_transitions.first.event).to eq "begin_coverage!"
    end

    it "should picks up the cover all auto renewing enrollment" do
      subject.begin_coverage_for_ivl_enrollments
      expect(cover_auto_renewing_enrollment.reload.aasm_state).to eq "coverage_selected"
      expect(cover_auto_renewing_enrollment.workflow_state_transitions.first.event).to eq "begin_coverage!"
    end

    it "should not break when there is an error with one of the enrollments." do
      renewing_selected_enrollment.unset(:family_id)
      renewing_selected_enrollment.reload
      subject.begin_coverage_for_ivl_enrollments
      expect(auto_renewing_enrollment.reload.aasm_state).to eq "coverage_selected"
      expect(auto_renewing_enrollment.workflow_state_transitions.first.event).to eq "begin_coverage!"
      expect(cover_auto_renewing_enrollment.reload.aasm_state).to eq "coverage_selected"
      expect(cover_auto_renewing_enrollment.workflow_state_transitions.first.event).to eq "begin_coverage!"
    end

    context 'when async_expire_and_begin_coverages feature is enabled' do
      before do
        allow(EnrollRegistry).to receive(:feature_enabled?).and_call_original
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:async_expire_and_begin_coverages).and_return(true)
      end

      it "should not raise error" do
        expect{subject.begin_coverage_for_ivl_enrollments}.not_to raise_error
      end
    end
  end

  context '#send_enr_or_dr_notice_to_ivl' do
    let(:created_at) { (TimeKeeper.date_of_record - 2.days).in_time_zone("Eastern Time (US & Canada)").beginning_of_day + 5.hours }

    context 'when document_reminder_notice_trigger is enabled' do
      before do
        allow(EnrollRegistry[:legacy_enrollment_trigger].feature).to receive(:is_enabled).and_return(false)
        allow(EnrollRegistry[:document_reminder_notice_trigger].feature).to receive(:is_enabled).and_return(true)
      end

      it 'should trigger document reminder notice' do
        # expect(::Operations::Notices::IvlDocumentReminderNotice).to receive_message_chain('new.call').with(family: family)
        subject.send_enr_or_dr_notice_to_ivl(TimeKeeper.date_of_record)
      end
    end

    context 'when legacy_enrollment_trigger is enabled' do
      before do
        allow(EnrollRegistry[:legacy_enrollment_trigger].feature).to receive(:is_enabled).and_return(true)
        allow(EnrollRegistry[:document_reminder_notice_trigger].feature).to receive(:is_enabled).and_return(false)
      end

      it 'should trigger legacy enrollment notice' do
        expect(::IvlNoticesNotifierJob).to receive(:perform_later).with(person.id.to_s, 'enrollment_notice')
        subject.send_enr_or_dr_notice_to_ivl(TimeKeeper.date_of_record)
      end
    end
  end
end
