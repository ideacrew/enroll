# frozen_string_literal: true

require "rails_helper"

RSpec.describe ::Operations::IvlOsseEligibilities::CreateIvlOsseEligibility,
               type: :model,
               dbclean: :around_each do
  let(:coverage_year) { Date.today.year }

  let(:hbx_profile) do
    FactoryBot.create(
      :hbx_profile,
      :normal_ivl_open_enrollment,
      coverage_year: coverage_year
    )
  end

  let(:benefit_coverage_period) do
    hbx_profile.benefit_sponsorship.benefit_coverage_periods.detect do |bcp|
      (bcp.start_on.year == coverage_year) &&
        bcp.start_on > bcp.open_enrollment_start_on
    end
  end

  let(:catalog_eligibility) do
    Operations::Eligible::CreateCatalogEligibility.new.call(
      {
        subject: benefit_coverage_period.to_global_id,
        eligibility_feature: "aca_ivl_osse_eligibility",
        effective_date: benefit_coverage_period.start_on.to_date,
        domain_model:
          "AcaEntities::BenefitSponsors::BenefitSponsorships::BenefitSponsorship"
      }
    )
  end

  let(:person) { FactoryBot.create(:person, :with_family, :with_consumer_role) }
  let!(:consumer_role) { person.consumer_role }
  let(:required_params) do
    {
      subject: consumer_role.to_global_id,
      effective_date: Date.today,
      evidence_key: :ivl_osse_evidence,
      evidence_value: evidence_value
    }
  end

  let(:evidence_value) { "false" }
  let!(:system_user) { FactoryBot.create(:user, email: "admin@dc.gov") }
  let(:trackable_event_instance) { Operations::EventLogs::TrackableEvent.new}

  before do
    allow(EnrollRegistry).to receive(:feature_enabled?).and_return(true)
    allow(trackable_event_instance).to receive(:publish).and_return(Dry::Monads::Success(true))
    allow(Operations::EventLogs::TrackableEvent).to receive(:new).and_return(trackable_event_instance)
    catalog_eligibility
  end

  context "with input params" do
    it "should build admin attested evidence options" do
      result = described_class.new.call(required_params)

      expect(result).to be_success
    end

    it "should create eligibility with :initial state evidence" do
      eligibility = described_class.new.call(required_params).success

      evidence = eligibility.reload.evidences.first
      eligibility_state_history = eligibility.state_histories.first
      evidence_state_history = evidence.state_histories.first

      expect(eligibility_state_history.event).to eq(:move_to_ineligible)
      expect(eligibility_state_history.from_state).to eq(:initial)
      expect(eligibility_state_history.to_state).to eq(:ineligible)
      expect(eligibility_state_history.is_eligible).to be_falsey

      expect(evidence_state_history.event).to eq(:move_to_not_approved)
      expect(evidence_state_history.from_state).to eq(:initial)
      expect(evidence_state_history.to_state).to eq(:not_approved)
      expect(evidence_state_history.is_eligible).to be_falsey
    end
  end

  context "with event approved" do
    let(:evidence_value) { "true" }

    it "should create eligibility with :approved state evidence" do
      eligibility = described_class.new.call(required_params).success

      evidence = eligibility.evidences.last
      eligibility_state_history = eligibility.state_histories.last
      evidence_state_history = evidence.state_histories.last

      expect(eligibility_state_history.event).to eq(:move_to_eligible)
      expect(eligibility_state_history.from_state).to eq(:initial)
      expect(eligibility_state_history.to_state).to eq(:eligible)
      expect(eligibility_state_history.is_eligible).to be_truthy

      expect(evidence_state_history.event).to eq(:move_to_approved)
      expect(evidence_state_history.from_state).to eq(:initial)
      expect(evidence_state_history.to_state).to eq(:approved)
      expect(evidence_state_history.is_eligible).to be_truthy
      expect(evidence.is_satisfied).to be_truthy
    end
  end

  context "when existing eligibility present" do
    let(:evidence_value) { "true" }

    let!(:ivl_osse_eligibility) do
      eligibility =
        build(
          :ivl_osse_eligibility,
          :with_admin_attested_evidence,
          evidence_state: :initial,
          is_eligible: false
        )
      consumer_role.eligibilities << eligibility
      consumer_role.save!
      eligibility
    end

    it "should create state history in tandem with existing evidence" do
      eligibility = described_class.new.call(required_params).success

      evidence = eligibility.evidences.last
      eligibility_state_history = eligibility.state_histories.last
      evidence_state_history = evidence.state_histories.last

      expect(eligibility_state_history.event).to eq(:move_to_eligible)
      expect(eligibility_state_history.from_state).to eq(:ineligible)
      expect(eligibility_state_history.to_state).to eq(:eligible)
      expect(eligibility_state_history.is_eligible).to be_truthy

      expect(evidence_state_history.event).to eq(:move_to_approved)
      expect(evidence_state_history.from_state).to eq(:initial)
      expect(evidence_state_history.to_state).to eq(:approved)
      expect(evidence_state_history.is_eligible).to be_truthy
      expect(evidence.is_satisfied).to be_truthy
    end
  end

  describe "#eligibility_event_for" do
    subject(:instance) { described_class.new }
    let(:prospective_eligibility) { false }

    before { instance.prospective_eligibility = prospective_eligibility }

    context "when default_eligibility is true" do

      it "should return false" do
        instance.default_eligibility = true
        expect(instance.send(:eligibility_event_for, :eligible)).to be_falsey
      end
    end

    context "when current_state is eligible" do
      let(:current_state) { :eligible }

      context "when prospective_eligibility is true" do
        let(:prospective_eligibility) { true }

        it "should return eligibility renewed event" do
          expect(instance.send(:eligibility_event_for, current_state)).to eq(
            "events.people.eligibilities.ivl_osse_eligibility.eligibility_renewed"
          )
        end
      end

      context "when prospective_eligibility is false" do
        let(:prospective_eligibility) { false }

        it "should return eligibility created event" do
          expect(instance.send(:eligibility_event_for, current_state)).to eq(
            "events.people.eligibilities.ivl_osse_eligibility.eligibility_created"
          )
        end
      end
    end

    context "when current_state is ineligible" do
      let(:current_state) { :ineligible }

      context "when prospective_eligibility is true" do
        let(:prospective_eligibility) { true }

        it "should return eligibility renewed event" do
          expect(instance.send(:eligibility_event_for, current_state)).to eq(
            "events.people.eligibilities.ivl_osse_eligibility.eligibility_renewed"
          )
        end
      end

      context "when prospective_eligibility is false" do
        let(:prospective_eligibility) { false }

        it "should return eligibility terminated event" do
          expect(instance.send(:eligibility_event_for, current_state)).to eq(
            "events.people.eligibilities.ivl_osse_eligibility.eligibility_terminated"
          )
        end
      end
    end
  end
end
