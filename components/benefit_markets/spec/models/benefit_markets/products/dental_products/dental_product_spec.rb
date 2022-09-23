# frozen_string_literal: true

RSpec.describe BenefitMarkets::Products::DentalProducts::DentalProduct, type: :model do

  describe 'attributes' do
    it { is_expected.to have_field(:ehb_apportionment_for_pediatric_dental).of_type(Float) }
  end
end
