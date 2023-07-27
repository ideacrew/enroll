# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BenefitSponsors::Operations::BenefitSponsorships::ShopOsseEligibility::PersistEligibility, type: :model, dbclean: :after_each do

  let(:required_params) do
    {
      evidence_key: :shop_osse_evidence,
      effective_date: Date.today,
      evidence_value: 'false',
      event: :initialize
    }
  end

  context 'with input params' do
    it 'should persit eligibility' do
      result = described_class.new.call(required_params)

      expect(result).to be_success
      expect(result.success).to be_a(BenefitSponsors::BenefitSponsorships::ShopOsseEligibility::ShopOsseEligibility)
    end
  end
end

