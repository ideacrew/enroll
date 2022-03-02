# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::Products::FetchSilverProducts, dbclean: :after_each do

  it 'should be a container-ready operation' do
    expect(subject.respond_to?(:call)).to be_truthy
  end

  describe 'invalid params' do

    let(:params) do
      {}
    end

    it 'should return failure' do
      result = subject.call(params)
      expect(result.failure?).to eq true
    end
  end

  describe 'valid params' do

    let(:person) { FactoryBot.create(:person, :with_consumer_role) }
    let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
    let(:rating_address) { person.consumer_role.rating_address }

    let!(:ivl_products) { FactoryBot.create_list(:benefit_markets_products_health_products_health_product, 5, :silver, benefit_market_kind: :aca_individual) }
    let!(:shop_products) { FactoryBot.create_list(:benefit_markets_products_health_products_health_product, 5, :silver, benefit_market_kind: :aca_shop) }
    let(:effective_date) { TimeKeeper.date_of_record }

    let(:params) do
      {
        address: rating_address,
        effective_date: effective_date
      }
    end

    context 'when address, rating area, service area exists' do

      it 'should return success' do
        result = subject.call(params)
        expect(result.success?).to eq true
      end

      it 'should return a hash of products' do
        result = subject.call(params)
        expect(result.value!.is_a?(Hash)).to eq true
      end

      it 'should return only ivl products' do
        result = subject.call(params).value!
        expect(result[:products].map(&:benefit_market_kind).uniq).to eq [:aca_individual]
      end
    end
  end
end
