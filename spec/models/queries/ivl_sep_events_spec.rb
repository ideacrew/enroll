# frozen_string_literal: true

require "rails_helper"

describe Queries::IvlSepEvents, "searching for terminations, with :silent_transition_enrollment ON", dbclean: :after_each do
  # We're going to be playing some games with start and end times here -
  # It's crucial for us that we don't have the events we want to match in the
  # same time span as the cancel.  Pay close attention below to when we first
  # reference start_time and end_time in each spec, as first reference is the
  # moment when RSpec 'initializes' the variable.
  let(:start_time) { Time.now }
  let(:end_time) { Time.now }

  let(:product) do
    FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health)
  end

  let(:family) do
    FactoryBot.create(:individual_market_family)
  end

  let(:enrollment) do
    hbx_enrollment = HbxEnrollment.new(
      :aasm_state => "shopping",
      :kind => "individual",
      :enrollment_kind => "open_enrollment",
      :coverage_kind => "health",
      :family => family,
      :household => family.households.first,
      :product => product,
      :rating_area_id => "ME0"
    )
    hbx_enrollment.save!
    hbx_enrollment.select_coverage!
    start_time
    hbx_enrollment
  end

  let(:same_window_enrollment) do
    start_time
    hbx_enrollment = HbxEnrollment.new(
      :aasm_state => "shopping",
      :kind => "individual",
      :enrollment_kind => "open_enrollment",
      :coverage_kind => "health",
      :family => family,
      :household => family.households.first,
      :product => product,
      :rating_area_id => "ME0"
    )
    hbx_enrollment.save!
    hbx_enrollment.select_coverage!
    hbx_enrollment
  end

  subject do
    query = described_class.new(start_time, end_time)
    map_by_hbx_id = query.terminations_during_window.map do |rec|
      HbxEnrollment.where(hbx_id: rec["_id"]).first
    end
    reject_for_reasons = map_by_hbx_id.reject do |en|
      query.has_silent_cancel?(en) || query.purchase_and_cancel_in_same_window?(en)
    end
    reject_for_reasons.map(&:hbx_id)
  end

  before :each do
    allow(EnrollRegistry).to receive(:feature_enabled?).and_call_original
    allow(EnrollRegistry).to receive(:feature_enabled?).with(:silent_transition_enrollment).and_return(true)
  end

  # Make sure we don't crash on old records which have no metadata.
  # Because the ORM will populate it with '{}' by default, we manually whack
  # it in the database using an update to remove the key from the model.
  it "matches cancels which have no metadata" do
    enrollment.cancel_coverage!
    end_time
    enrollment.reload
    wft_index = 0
    enrollment.workflow_state_transitions.each_with_index do |wft, idx|
      if wft.to_state == Enrollments::WorkflowStates::COVERAGE_CANCELED
        wft_index = idx
        break
      end
    end
    HbxEnrollment.where(hbx_id: enrollment.hbx_id).update_all(
      {
        "$unset" => { "workflow_state_transitions.#{wft_index}.metadata" => "" }
      }
    )
    expect(subject).to include(enrollment.hbx_id)
  end

  it "matches cancels which have metadata with a different reason code" do
    enrollment.cancel_coverage!({reason: "MAKE SOMETHING UP"})
    end_time
    expect(subject).to include(enrollment.hbx_id)
  end

  it "does not match cancels which have the excluded reason" do
    enrollment.cancel_coverage!({reason: Enrollments::TerminationReasons::SUPERSEDED_SILENT})
    end_time
    expect(subject).not_to include(enrollment.hbx_id)
  end

  it "does not match a term which was then canceled with the excluded reason" do
    enrollment.terminate_coverage!(Date.today + 30.days)

    previous_state = enrollment.aasm_state
    enrollment.update_attributes(aasm_state: Enrollments::WorkflowStates::COVERAGE_CANCELED)
    enrollment.workflow_state_transitions << WorkflowStateTransition.new(
      {
        from_state: previous_state,
        to_state: Enrollments::WorkflowStates::COVERAGE_CANCELED,
        metadata: {
          reason: Enrollments::TerminationReasons::SUPERSEDED_SILENT
        }
      }
    )
    end_time
    expect(subject).not_to include(enrollment.hbx_id)
  end

  it "does not match an enrollment which was purchased and then canceled in the same window" do
    same_window_enrollment.cancel_coverage!
    end_time
    expect(subject).not_to include(same_window_enrollment.hbx_id)
  end
end

describe Queries::IvlSepEvents, "searching for terminations, with :silent_transition_enrollment OFF", dbclean: :after_each do
  # We're going to be playing some games with start and end times here -
  # It's crucial for us that we don't have the events we want to match in the
  # same time span as the cancel.  Pay close attention below to when we first
  # reference start_time and end_time in each spec, as first reference is the
  # moment when RSpec 'initializes' the variable.
  let(:start_time) { Time.now }
  let(:end_time) { Time.now }

  let(:product) do
    FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health)
  end

  let(:family) do
    FactoryBot.create(:individual_market_family)
  end

  let(:enrollment) do
    hbx_enrollment = HbxEnrollment.new(
      :aasm_state => "shopping",
      :kind => "individual",
      :enrollment_kind => "open_enrollment",
      :coverage_kind => "health",
      :family => family,
      :household => family.households.first,
      :product => product,
      :rating_area_id => "ME0"
    )
    hbx_enrollment.save!
    hbx_enrollment.select_coverage!
    start_time
    hbx_enrollment
  end

  let(:same_window_enrollment) do
    start_time
    hbx_enrollment = HbxEnrollment.new(
      :aasm_state => "shopping",
      :kind => "individual",
      :enrollment_kind => "open_enrollment",
      :coverage_kind => "health",
      :family => family,
      :household => family.households.first,
      :product => product,
      :rating_area_id => "ME0"
    )
    hbx_enrollment.save!
    hbx_enrollment.select_coverage!
    hbx_enrollment
  end

  subject do
    query = described_class.new(start_time, end_time)
    map_by_hbx_id = query.terminations_during_window.map do |rec|
      HbxEnrollment.where(hbx_id: rec["_id"]).first
    end
    reject_for_reasons = map_by_hbx_id.reject do |en|
      query.has_silent_cancel?(en) || query.purchase_and_cancel_in_same_window?(en)
    end
    reject_for_reasons.map(&:hbx_id)
  end

  before :each do
    allow(EnrollRegistry).to receive(:feature_enabled?).and_call_original
    allow(EnrollRegistry).to receive(:feature_enabled?).with(:silent_transition_enrollment).and_return(false)
  end

  # Make sure we don't crash on old records which have no metadata.
  # Because the ORM will populate it with '{}' by default, we manually whack
  # it in the database using an update to remove the key from the model.
  it "matches cancels which have no metadata" do
    enrollment.cancel_coverage!
    end_time
    enrollment.reload
    wft_index = 0
    enrollment.workflow_state_transitions.each_with_index do |wft, idx|
      if wft.to_state == Enrollments::WorkflowStates::COVERAGE_CANCELED
        wft_index = idx
        break
      end
    end
    HbxEnrollment.where(hbx_id: enrollment.hbx_id).update_all(
      {
        "$unset" => { "workflow_state_transitions.#{wft_index}.metadata" => "" }
      }
    )
    expect(subject).to include(enrollment.hbx_id)
  end

  it "matches cancels which have metadata with a different reason code" do
    enrollment.cancel_coverage!({reason: "MAKE SOMETHING UP"})
    end_time
    expect(subject).to include(enrollment.hbx_id)
  end

  it "matches cancels which have the excluded reason" do
    enrollment.cancel_coverage!({reason: Enrollments::TerminationReasons::SUPERSEDED_SILENT})
    end_time
    expect(subject).to include(enrollment.hbx_id)
  end

  it "matches a term which was then canceled with the excluded reason" do
    enrollment.terminate_coverage!(Date.today + 30.days)

    previous_state = enrollment.aasm_state
    enrollment.update_attributes(aasm_state: Enrollments::WorkflowStates::COVERAGE_CANCELED)
    enrollment.workflow_state_transitions << WorkflowStateTransition.new(
      {
        from_state: previous_state,
        to_state: Enrollments::WorkflowStates::COVERAGE_CANCELED,
        metadata: {
          reason: Enrollments::TerminationReasons::SUPERSEDED_SILENT
        }
      }
    )
    end_time
    expect(subject).to include(enrollment.hbx_id)
  end

  it "matches an enrollment which was purchased and then canceled in the same window" do
    same_window_enrollment.cancel_coverage!
    end_time
    expect(subject).to include(same_window_enrollment.hbx_id)
  end
end

describe Queries::IvlSepEvents, "searching for purchases, with :silent_transition_enrollment ON", dbclean: :after_each do
  # We're going to be playing some games with start and end times here -
  # It's crucial for us that we don't have the events we want to match in the
  # same time span as the cancel.  Pay close attention below to when we first
  # reference start_time and end_time in each spec, as first reference is the
  # moment when RSpec 'initializes' the variable.
  let(:start_time) { Time.now }
  let(:end_time) { Time.now }

  let(:product) do
    FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health)
  end

  let(:family) do
    FactoryBot.create(:individual_market_family)
  end

  let(:same_window_enrollment) do
    start_time
    hbx_enrollment = HbxEnrollment.new(
      :aasm_state => "shopping",
      :kind => "individual",
      :enrollment_kind => "open_enrollment",
      :coverage_kind => "health",
      :family => family,
      :household => family.households.first,
      :product => product,
      :rating_area_id => "ME0"
    )
    hbx_enrollment.save!
    hbx_enrollment.select_coverage!
    hbx_enrollment
  end

  before :each do
    allow(EnrollRegistry).to receive(:feature_enabled?).and_call_original
    allow(EnrollRegistry).to receive(:feature_enabled?).with(:silent_transition_enrollment).and_return(true)
  end

  subject do
    query = described_class.new(start_time, end_time)
    map_by_hbx_id = query.selections_during_window.map do |rec|
      HbxEnrollment.where(hbx_id: rec["_id"]).first
    end
    reject_for_reasons = map_by_hbx_id.reject do |en|
      query.purchase_and_cancel_in_same_window?(en)
    end
    reject_for_reasons.map(&:hbx_id)
  end

  it "does not match an enrollment which was purchased and then canceled in the same window" do
    same_window_enrollment.cancel_coverage!
    end_time
    expect(subject).not_to include(same_window_enrollment.hbx_id)
  end
end

describe Queries::IvlSepEvents, "searching for purchases, with :silent_transition_enrollment OFF", dbclean: :after_each do
  # We're going to be playing some games with start and end times here -
  # It's crucial for us that we don't have the events we want to match in the
  # same time span as the cancel.  Pay close attention below to when we first
  # reference start_time and end_time in each spec, as first reference is the
  # moment when RSpec 'initializes' the variable.
  let(:start_time) { Time.now }
  let(:end_time) { Time.now }

  let(:product) do
    FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health)
  end

  let(:family) do
    FactoryBot.create(:individual_market_family)
  end

  let(:same_window_enrollment) do
    start_time
    hbx_enrollment = HbxEnrollment.new(
      :aasm_state => "shopping",
      :kind => "individual",
      :enrollment_kind => "open_enrollment",
      :coverage_kind => "health",
      :family => family,
      :household => family.households.first,
      :product => product,
      :rating_area_id => "ME0"
    )
    hbx_enrollment.save!
    hbx_enrollment.select_coverage!
    hbx_enrollment
  end

  before :each do
    allow(EnrollRegistry).to receive(:feature_enabled?).and_call_original
    allow(EnrollRegistry).to receive(:feature_enabled?).with(:silent_transition_enrollment).and_return(false)
  end

  subject do
    query = described_class.new(start_time, end_time)
    map_by_hbx_id = query.selections_during_window.map do |rec|
      HbxEnrollment.where(hbx_id: rec["_id"]).first
    end
    reject_for_reasons = map_by_hbx_id.reject do |en|
      query.purchase_and_cancel_in_same_window?(en)
    end
    reject_for_reasons.map(&:hbx_id)
  end

  it "matches an enrollment which was purchased and then canceled in the same window" do
    same_window_enrollment.cancel_coverage!
    end_time
    expect(subject).to include(same_window_enrollment.hbx_id)
  end
end

RSpec.describe Queries::IvlSepEvents, dbclean: :after_each do
  describe '#terminations_during_window' do
    let(:purchase_event_published_at) { nil }
    let(:enrollment) { double('HbxEnrollment', purchase_event_published_at: purchase_event_published_at) }
    let(:ivl_sep_event) { described_class.new(Time.now, Time.now) }

    before do
      allow(EnrollRegistry).to receive(:feature_enabled?).and_call_original
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:silent_transition_enrollment).and_return(enabled_or_disabled)
    end

    context 'feature :silent_transition_enrollment is disabled' do
      let(:enabled_or_disabled) { false }

      it 'returns true as feature is disabled' do
        expect(ivl_sep_event.skip_termination?(enrollment)).to be_truthy
      end
    end

    context 'feature :silent_transition_enrollment is enabled' do
      let(:enabled_or_disabled) { true }

      context 'enrollment has no purchase_event_published_at' do

        it 'returns true as purchase_event_published_at is nil' do
          expect(ivl_sep_event.skip_termination?(enrollment)).to be_truthy
        end
      end

      context 'enrollment has a purchase_event_published_at' do
        let(:purchase_event_published_at) { DateTime.now }

        it 'returns true as purchase_event_published_at is populated' do
          expect(ivl_sep_event.skip_termination?(enrollment)).to be_falsey
        end
      end
    end
  end
end
