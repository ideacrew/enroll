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

  before do
    allow(EnrollRegistry).to receive(:feature_enabled?).and_return(true)
    catalog_eligibility
  end

  context "with input params" do
    let(:operation) do
      operation = described_class.new
      operation.default_eligibility = true
      operation
    end

    it "should build admin attested evidence options" do
      result = described_class.new.call(required_params)

      expect(result).to be_success
    end

    it "should create eligibility with :initial state evidence" do
      operation.call(required_params).success

      eligibility = consumer_role.reload.eligibilities.last
      evidence = eligibility.evidences.first
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

    let(:operation) do
      operation = described_class.new
      operation.default_eligibility = true
      operation
    end

    it "should create state history in tandem with existing evidence" do
      eligibility = operation.call(required_params).success

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
end
