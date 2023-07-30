# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BenefitSponsors::Operations::BenefitSponsorships::ShopOsseEligibilities::BuildShopOsseGrant, type: :model, dbclean: :after_each do

  let(:required_params) do
    {
      grant_type: :min_employee_participation_relaxed_grant,
      grant_key: :min_employee_participation_relaxed,
      grant_value: true,
      effective_date: Date.today,
      is_eligible: true
    }
  end

  context 'with input params' do
    it 'should build admin attested evidence' do
      result = described_class.new.call(required_params)

      expect(result).to be_success
    end
  end
end
