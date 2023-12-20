# frozen_string_literal: true

require 'rails_helper'

describe 'ivl_sep_query', dbclean: :after_each do
  before :all do
    DatabaseCleaner.clean
  end

  let(:product) do
    FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health)
  end

  let(:family) do
    FactoryBot.create(
      :family, :with_primary_family_member,
      person: FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role)
    )
  end

  let(:purchase_event_published_at) { nil }

  let(:enrollment) do
    FactoryBot.create(
      :hbx_enrollment,
      :individual_shopping,
      :with_enrollment_members,
      effective_on: TimeKeeper.date_of_record.beginning_of_month,
      household: family.households.first,
      family: family,
      product: product,
      coverage_kind: 'health',
      rating_area_id: 'ME0',
      purchase_event_published_at: purchase_event_published_at,
      enrollment_members: family.active_family_members,
      consumer_role_id: family.primary_person.consumer_role.id
    )
  end

  let(:purchases) { [] }
  let(:terms) { [] }
  let(:query) { double('Queries::IvlSepEvents', selections_during_window: purchases, terminations_during_window: terms) }
  let(:decorated_hbx_enrollment) { double('HbxEnrollmentDecorator', total_premium: 1000.0) }
  let(:enabled_or_disabled) { false }
  let(:purchase_and_cancel_in_same_window_true_or_false) { false }
  let(:skip_termination_true_or_false) { false }
  let(:has_silent_cancel_true_or_false) { false }
  let(:logger_content) { File.read(File.join(Rails.root, 'log', 'test.log')) }

  before :each do
    allow(EnrollRegistry).to receive(:feature_enabled?).and_call_original
    allow(EnrollRegistry).to receive(:feature_enabled?).with(:silent_transition_enrollment).and_return(enabled_or_disabled)
    allow(Queries::IvlSepEvents).to receive(:new).with(any_args).and_return(query)
    allow(HbxEnrollment).to receive(:where).and_call_original
    allow(HbxEnrollment).to receive(:where).with(hbx_id: input_enrollment.hbx_id).and_return([input_enrollment])
    allow(input_enrollment).to receive(:decorated_hbx_enrollment).and_return(decorated_hbx_enrollment)
    allow(query).to receive(:purchase_and_cancel_in_same_window?).with(input_enrollment).and_return(
      purchase_and_cancel_in_same_window_true_or_false
    )
    allow(query).to receive(:skip_termination?).with(input_enrollment).and_return(
      skip_termination_true_or_false
    )
    allow(query).to receive(:has_silent_cancel?).with(input_enrollment).and_return(
      has_silent_cancel_true_or_false
    )
    invoke_ivl_sep_query
  end

  context 'acapi.info.events.hbx_enrollment.coverage_selected' do
    let(:input_enrollment) do
      enrollment.select_coverage!
      enrollment
    end

    let(:purchases) { [{ '_id' => input_enrollment.hbx_id, 'created_at' => input_enrollment.created_at.to_s, 'enrollment_state' => 'coverage_selected' }] }

    it 'updates purchase_event_published_at' do
      expect(input_enrollment.reload.purchase_event_published_at).to be_present
    end

    it 'logs message' do
      expect(logger_content).to include(
        "Published event: acapi.info.events.hbx_enrollment.coverage_selected for enrollment hbx_id: #{input_enrollment.hbx_id}"
      )
    end
  end

  context 'acapi.info.events.hbx_enrollment.terminated' do
    let(:input_enrollment) do
      enrollment.select_coverage!
      enrollment.terminate_coverage!
      enrollment
    end

    let(:terms) { [{ '_id' => input_enrollment.hbx_id, 'created_at' => input_enrollment.created_at.to_s }] }

    context 'when query.skip_termination returns true' do
      let(:purchase_event_published_at) { DateTime.now }
      let(:enabled_or_disabled) { true }
      let(:purchase_and_cancel_in_same_window_true_or_false) { true }
      let(:skip_termination_true_or_false) { true }

      it 'returns without publishing the event' do
        expect(IvlEnrollmentsPublisher).not_to receive(:publish_action).with(
          'acapi.info.events.hbx_enrollment.terminated',
          input_enrollment.hbx_id,
          'urn:openhbx:terms:v1:enrollment#terminate_enrollment'
        )

        invoke_ivl_sep_query
      end
    end

    context 'when publish is invoked' do
      let(:purchase_event_published_at) { DateTime.now }
      let(:enabled_or_disabled) { true }
      let(:purchase_and_cancel_in_same_window_true_or_false) { false }

      it 'returns without publishing the event' do
        expect(logger_content).to include(
          "Published event: acapi.info.events.hbx_enrollment.terminated for enrollment hbx_id: #{input_enrollment.hbx_id}"
        )
      end
    end
  end
end

def invoke_ivl_sep_query
  load File.join(Rails.root, 'script/ivl_sep_query.rb')
end
