# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BenefitSponsors::Operations::BenefitSponsorships::ShopOsseEligibility::BuildGrant, type: :model, dbclean: :after_each do

  let(:required_params) do
    {
      grant_type: :min_employee_participation_relaxed_grant,
      grant_key: :min_employee_participation_relaxed,
      grant_value: true,
      effective_date: Date.today,
      is_eligible: true,
    }
  end

  context 'with input params' do
    it 'should build admin attested evidence' do
      result = described_class.new.call(required_params)

      expect(result).to be_success
      expect(result.success).to be_a(BenefitSponsors::BenefitSponsorships::ShopOsseEligibility::Grant)
    end

    it 'should create state history with attested state' do
      grant = described_class.new.call(required_params).success

      state_history = grant.latest_state_history
      expect(state_history.event).to eq(:move_to_active)
      expect(state_history.from_state).to eq(:draft)
      expect(state_history.to_state).to eq(:active)
    end

    it 'should create default initialized state history' do
      grant = described_class.new.call(required_params).success

      state_history = grant.state_histories.first
      expect(state_history.event).to eq(:initialize)
      expect(state_history.from_state).to eq(:draft)
      expect(state_history.to_state).to eq(:draft)
    end
  end
end
