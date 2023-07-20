# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BenefitSponsors::Operations::BenefitSponsorships::ShopOsseEligibility::BuildEligibility, type: :model, dbclean: :after_each do

  let(:required_params) do
    {
      evidence_key: :hc4cc,
      effective_date: Date.today,
      evidence_value: 'true'
    }
  end

  context 'with input params' do
    it 'should build admin attested evidence' do
      result = described_class.new.call(required_params)

      expect(result).to be_success
      expect(result.success).to be_a(BenefitSponsors::BenefitSponsorships::ShopOsseEligibility::Eligibility)
    end

    it 'should create state history with attested state' do
      evidence = described_class.new.call(required_params).success

      state_history = evidence.latest_state_history
      expect(state_history.event).to eq(:move_to_ineligible)
      expect(state_history.from_state).to eq(:draft)
      expect(state_history.to_state).to eq(:ineligible)
    end

    it 'should create default initialized state history' do
      evidence = described_class.new.call(required_params).success

      state_history = evidence.state_histories.first
      expect(state_history.event).to eq(:initialize)
      expect(state_history.from_state).to eq(:draft)
      expect(state_history.to_state).to eq(:draft)
    end
  end
end
