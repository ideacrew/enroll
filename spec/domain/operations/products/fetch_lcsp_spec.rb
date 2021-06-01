# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::Products::FetchLcsp, dbclean: :after_each do

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

    before :each do
      allow(Operations::Products::FetchSilverProductPremiums).to receive(:new).and_return double(call: ::Dry::Monads::Result::Success.new(silver_product_premiums))
    end


    it 'should return success' do
      result = subject.call(params)
      expect(result.success?).to eq true
    end

    it 'should return an array of lcsp for the given family' do
      result = subject.call(params)
      expect(result.value!.is_a?(Array)).to eq true
    end

    it 'should return premium & product id of lowest plan' do
      values = subject.call(params).value!.collect {|p| p[family_member_id]}[0]
      expect(values[:cost]).to eq 200.0
      expect(values[:product_id]).not_to eq nil
    end
  end
end
