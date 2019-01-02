require 'rails_helper'

module BenefitMarkets
  RSpec.describe Forms::ProductForm do
    describe '::for_new' do
      let(:product) { create :benefit_markets_products_product }
      subject { BenefitMarkets::Forms::ProductForm.for_new }

      it 'instantiates a new Product Form' do
        expect(subject).to be_an_instance_of(BenefitMarkets::Forms::ProductForm)
      end
    end
  end
end
