require 'rails_helper'

module BenefitMarkets
  RSpec.describe Products::ProductFactory, type: :model do

    describe "#has_rates?" do
      let!(:product) { FactoryGirl.create(:benefit_markets_products_health_products_health_product) }

      it "should return true if rates are available with atleast one carrier" do
        expect(::BenefitMarkets::Products::ProductFactory.new(TimeKeeper.date_of_record).has_rates?).to eq true
      end

      it "should return false if rates are not available from all carriers" do
        expect(::BenefitMarkets::Products::ProductFactory.new(TimeKeeper.date_of_record-1.year).has_rates?).to eq false
      end
    end
  end
end