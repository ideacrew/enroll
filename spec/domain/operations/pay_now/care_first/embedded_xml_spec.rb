# frozen_string_literal: true

require "rails_helper"

RSpec.describe Operations::PayNow::CareFirst::EmbeddedXml do
  let!(:person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, csr_variant_id: "01") }
  let!(:hbx_enrollment) { FactoryBot.create(:hbx_enrollment, family: family, household: family.active_household, aasm_state: "shopping", product: product) }

  describe "payload is incomplete" do
    it "fails with incomplete payload" do
      result = described_class.new.call("000000")
      expect(result.success?).to be_falsey
      expect(result.failure).to eq("unable to transform hbx enrollment 000000")
    end
  end
end
