# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::Products::Fetch, dbclean: :after_each do

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
    let(:family_member_id) { family.family_members.first.id.to_s }

    let(:effective_date) { TimeKeeper.date_of_record }
    let(:params) do
      {
        family: family,
        effective_date: effective_date
      }
    end

    let(:silver_product_premiums) do
      {
        family_member_id => [
          { :cost => 200.0, :product_id => BSON::ObjectId.new },
          { :cost => 300.0, :product_id => BSON::ObjectId.new },
          { :cost => 400.0, :product_id => BSON::ObjectId.new }
        ]
      }
    end

    let!(:list_products) { FactoryBot.create_list(:benefit_markets_products_health_products_health_product, 5, :silver) }

    let(:products) { ::BenefitMarkets::Products::Product.all }
    let(:products_payload) do
      {
        rating_area_id: BSON::ObjectId.new,
        products: products
      }
    end

    before :each do
      allow(Operations::Products::FetchSilverProducts).to receive(:new).and_return double(call: ::Dry::Monads::Result::Success.new(products_payload))
      allow(Operations::Products::FetchSilverProductPremiums).to receive(:new).and_return double(call: ::Dry::Monads::Result::Success.new(silver_product_premiums))
    end


    it 'should return success' do
      result = subject.call(params)
      expect(result.success?).to eq true
    end

    it 'should return an array of slcsp for the given family' do
      value = subject.call(params).value!
      expect(value.is_a?(Hash)).to eq true
      expect(value[[person.hbx_id]].keys.include?(:health_only)).to eq true
    end

    context 'all members without rating area' do
      before do
        family.family_members.each do |f_member|
          f_member.person.addresses.each { |addr| addr.update_attributes!(kind: 'work') }
        end
        @result = subject.call(params)
      end

      it 'should return a failure' do
        expect(@result.failure?).to be_truthy
      end

      it 'should return failure with a message' do
        expect(@result.failure).to eq("Unable to find rating addresses for at least one family member for given family with id: #{family.id}")
      end
    end
  end
end
