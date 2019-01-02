require 'rails_helper'

module BenefitMarkets
  RSpec.describe Forms::ProductForm do
    describe '::for_new' do
      let(:product) { create :benefit_markets_products_product }
      let(:date) { TimeKeeper.date_of_record }
      let(:future_year) { (date+1.year).year }
      let!(:product) { FactoryGirl.create(:benefit_markets_products_health_products_health_product) }

      subject { BenefitMarkets::Forms::ProductForm.for_new(date) }

      it 'should instantiate a new Product Form' do
        expect(subject).to be_an_instance_of(BenefitMarkets::Forms::ProductForm)
      end

      it 'should return false if rates are present' do
        expect(subject.fetch_results.is_late_rate).to eq false
      end

      it 'should return true if rates are not present' do
        product.application_period = Date.new(future_year, 1, 1)..Date.new(future_year, 12, 31)
        pt = product.premium_tables.first
        pt.effective_period = product.application_period
        product.save
        expect(subject.fetch_results.is_late_rate).to eq true
      end
    end
  end
end
