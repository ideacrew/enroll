# frozen_string_literal: true

require "rails_helper"

RSpec.describe ::Operations::IvlOsseEligibilities::CreateIvlOsseEligibility, type: :model, dbclean: :after_each do
  let(:person) { FactoryBot.create(:person, :with_family, :with_consumer_role)}
  let(:consumer_role) { person.consumer_role }
  let(:required_params) do
    {
      subject: consumer_role.to_global_id,
      effective_date: Date.today,
      evidence_key: :ivl_osse_evidence,
      evidence_value: evidence_value
    }
  end

  let(:evidence_value) { "false" }

  context "with input params" do
    it "should build admin attested evidence options" do
      result = described_class.new.call(required_params)

      expect(result).to be_success
    end

    it "should create eligibility with :initial state evidence" do
      eligibility = described_class.new.call(required_params).success

      evidence = eligibility.evidences.last
      eligibility_state_history = eligibility.state_histories.last
      evidence_state_history = evidence.state_histories.last

      expect(eligibility_state_history.event).to eq(:move_to_initial)
      expect(eligibility_state_history.from_state).to eq(:initial)
      expect(eligibility_state_history.to_state).to eq(:initial)
      expect(eligibility_state_history.is_eligible).to be_falsey

      expect(evidence_state_history.event).to eq(:move_to_initial)
      expect(evidence_state_history.from_state).to eq(:initial)
      expect(evidence_state_history.to_state).to eq(:initial)
      expect(evidence_state_history.is_eligible).to be_falsey
      expect(evidence.is_satisfied).to be_falsey
    end
  end

  context "with event approved" do
    let(:evidence_value) { "true" }

    it "should create eligibility with :approved state evidence" do
      eligibility = described_class.new.call(required_params).success

      evidence = eligibility.evidences.last
      eligibility_state_history = eligibility.state_histories.last
      evidence_state_history = evidence.state_histories.last

      expect(eligibility_state_history.event).to eq(:move_to_published)
      expect(eligibility_state_history.from_state).to eq(:initial)
      expect(eligibility_state_history.to_state).to eq(:published)
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
      consumer_role.ivl_eligibilities << eligibility
      consumer_role.save!
      eligibility
    end

    it "should create state history in tandem with existing evidence" do
      eligibility = described_class.new.call(required_params).success

      evidence = eligibility.evidences.last
      eligibility_state_history = eligibility.state_histories.last
      evidence_state_history = evidence.state_histories.last

      expect(eligibility_state_history.event).to eq(:move_to_published)
      expect(eligibility_state_history.from_state).to eq(:initial)
      expect(eligibility_state_history.to_state).to eq(:published)
      expect(eligibility_state_history.is_eligible).to be_truthy

      expect(evidence_state_history.event).to eq(:move_to_approved)
      expect(evidence_state_history.from_state).to eq(:initial)
      expect(evidence_state_history.to_state).to eq(:approved)
      expect(evidence_state_history.is_eligible).to be_truthy
      expect(evidence.is_satisfied).to be_truthy
    end
  end
end
