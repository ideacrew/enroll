# frozen_string_literal: true

require 'rails_helper'
RSpec.describe ::Operations::Eligibilities::Notices::RequestDocumentReminderNotices,
               type: :model,
               dbclean: :after_each do
  it 'should be a container-ready operation' do
    expect(subject.respond_to?(:call)).to be_truthy
  end

  describe 'Create reminder request' do
    let(:person) { create(:person, :with_consumer_role) }
    let(:family) do
      create(:family, :with_primary_family_member, person: person)
    end
    let(:issuer) do
      create(:benefit_sponsors_organizations_issuer_profile, abbrev: 'ANTHM')
    end
    let(:product) do
      create(
        :benefit_markets_products_health_products_health_product,
        :ivl_product,
        issuer_profile: issuer
      )
    end
    let(:enrollment) do
      create(
        :hbx_enrollment,
        :with_enrollment_members,
        :individual_unassisted,
        family: family,
        product_id: product.id,
        applied_aptc_amount: Money.new(44_500),
        consumer_role_id: person.consumer_role.id,
        enrollment_members: family.family_members
      )
    end

    context 'with invalid params' do
      let(:params) { {} }

      it 'should return failure' do
        result = subject.call(params)
        expect(result.failure?).to be_truthy
        expect(result.failure).to include 'date of record missing'
      end

      context 'when invalid date format is passed in' do
        let(:params) { { date_of_record: Date.today.to_s } }

        it 'should return failure' do
          result = subject.call(params)
          expect(result.failure?).to be_truthy
          expect(result.failure).to include 'date of record should be an instance of Date'
        end
      end
    end

    context 'with valid params' do
      before :each do
        person.consumer_role.verification_types.each do |vt|
          vt.update_attributes(
            validation_status: 'outstanding',
            due_date: TimeKeeper.date_of_record - 1.day
          )
        end

        allow(Family).to receive(:outstanding_verifications_expiring_on)
          .and_call_original
        allow(Family).to receive(:outstanding_verifications_expiring_on)
          .with(Date.today + 94.days)
          .and_return([family])
      end

      let(:params) { { date_of_record: Date.today } }

      let(:reminder_notices) do
        EnrollRegistry[:ivl_eligibility_notices].settings(:document_reminders)
                                                .item
      end

      it 'should return success' do
        result = subject.call(params)
        expect(result.success?).to be_truthy
      end

      it 'should return results with reminder notice keys' do
        result = subject.call(params)
        payload = result.success.payload

        reminder_notices.each do |notice_key|
          expect(payload.key?(notice_key)).to be_truthy
        end
      end

      context 'when there is an exception' do
        before do
          allow(Operations::Eligibilities::Notices::CreateReminderRequest).to receive_message_chain('new.call')
            .with(anything).and_raise('Run time error')
        end

        it 'should return success' do
          result = subject.call(params)
          expect(result.success?).to be_truthy
        end
      end
    end
  end

  describe 'alive_status' do
    let(:person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
    let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
    let(:alive_status) { person.alive_status }
    let(:enrollment) do
      FactoryBot.create(
        :hbx_enrollment,
        :individual_unassisted,
        :with_silver_health_product,
        effective_on: today,
        family: family,
        household: family.active_household,
        aasm_state: enrollment_state
      )
    end

    let(:enrollment_member) do
      FactoryBot.create(
        :hbx_enrollment_member,
        hbx_enrollment: enrollment,
        applicant_id: family.primary_applicant.id
      )
    end

    before :each do
      allow(EnrollRegistry).to receive(:feature_enabled?).and_call_original
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:alive_status).and_return(true)
      allow(EnrollRegistry[:alive_status]).to receive(:enabled?).and_return(true)
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:trigger_document_reminder_notices_at_individual_level).and_return(true)
      enrollment_member
      alive_status.fail_type
      person.save
      person.reload
      ::Operations::Eligibilities::BuildFamilyDetermination.new.call(
        family: family, effective_date: today
      )
    end

    let(:document_reminder_key) { :document_reminder_0 }

    let(:today) { TimeKeeper.date_of_record }

    let(:due_date) do
      eli_state = family.eligibility_determination.subjects.first.eligibility_states.detect do |es|
        es.eligibility_item_key == 'aca_individual_market_eligibility'
      end

      eli_state.evidence_states.detect do |evi_s|
        evi_s.evidence_item_key == :alive_status
      end.due_on
    end

    let(:offset_prior_to_due_date) do
      feature = EnrollRegistry[document_reminder_key]
      offset = feature.settings(:offset_prior_to_due_date).item
      units = feature.settings(:units).item
      offset.send(units)
    end

    context 'with a person:
      - enrolled in an active health insurance plan
      - has alive_status in outstanding or rejected state
      - the due date is set for alive_status as today
      - input date is eligible date for a reminder notice
    ' do

      let(:enrollment_state) { 'coverage_selected' }

      let(:expected_family_payload) do
        {
          date_of_record: input_date,
          document_reminder_key: document_reminder_key,
          family_id: family.id
        }
      end

      let(:expected_payload) do
        {
          document_reminder_0: { successes: [{ family_hbx_id: family.hbx_assigned_id }], failures: [] },
          document_reminder_1: { successes: [], failures: [] },
          document_reminder_2: { successes: [], failures: [] },
          document_reminder_3: { successes: [], failures: [] },
          document_reminder_4: { successes: [], failures: [] }
        }
      end

      let(:input_date) do
        due_date - offset_prior_to_due_date
      end

      it 'triggers both individual family level event for generating reminder notices and also triggers success event' do
        expect(subject).to receive(:event).with(
          'events.individual.notices.request_batch_verification_reminders',
          attributes: expected_family_payload
        ).and_call_original

        expect(subject).to receive(:event).with(
          'events.enterprise.document_reminder_notices_processed',
          attributes: expected_payload
        ).and_call_original

        subject.call({ date_of_record: input_date })
      end
    end

    context 'with a person:
      - enrolled in an active health insurance plan
      - has alive_status in outstanding or rejected state
      - the due date is set for alive_status as today
      - input date is NOT an eligible date for a reminder notice
    ' do

      let(:enrollment_state) { 'coverage_selected' }

      let(:expected_payload) do
        {
          document_reminder_0: { successes: [], failures: [] },
          document_reminder_1: { successes: [], failures: [] },
          document_reminder_2: { successes: [], failures: [] },
          document_reminder_3: { successes: [], failures: [] },
          document_reminder_4: { successes: [], failures: [] }
        }
      end

      let(:input_date) { today }

      it 'only triggers success event at the end without any successes or failures' do
        expect(subject).to receive(:event).with(
          'events.enterprise.document_reminder_notices_processed',
          attributes: expected_payload
        ).and_call_original

        subject.call({ date_of_record: input_date })
      end
    end

    context 'with a person:
      - enrolled in a health insurance plan that is not active
      - has alive_status in outstanding or rejected state
      - the due date is set for alive_status as today
      - input date is NOT an eligible date for a reminder notice
    ' do

      let(:enrollment_state) { 'coverage_terminated' }

      let(:expected_payload) do
        {
          document_reminder_0: { successes: [], failures: [] },
          document_reminder_1: { successes: [], failures: [] },
          document_reminder_2: { successes: [], failures: [] },
          document_reminder_3: { successes: [], failures: [] },
          document_reminder_4: { successes: [], failures: [] }
        }
      end

      let(:input_date) { today }

      it 'only triggers success event at the end without any successes or failures' do
        expect(subject).to receive(:event).with(
          'events.enterprise.document_reminder_notices_processed',
          attributes: expected_payload
        ).and_call_original

        subject.call({ date_of_record: input_date })
      end
    end
  end
end
