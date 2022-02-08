# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::Products::ProductOfferedInServiceArea, dbclean: :after_each do

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

    let(:enrollment) { FactoryBot.build(:hbx_enrollment, :individual_shopping, :with_health_product, family: family, consumer_role_id: consumer_role.id, rating_area_id: rating_area.id) }
    let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
    let(:person) { FactoryBot.create(:person, :with_consumer_role)}
    let(:consumer_role) { person.consumer_role }
    let(:address) { consumer_role.rating_address }
    let(:rating_area) { ::BenefitMarkets::Locations::RatingArea.rating_area_for(address) || FactoryBot.create(:benefit_markets_locations_rating_area) }

    let(:params) do
      { enrollment: enrollment }
    end

    context 'when product not offered in service area' do

      before :each do
        allow(EnrollRegistry[:service_area].setting(:service_area_model)).to receive(:item).and_return('county')
        address.update_attributes(county: "Zip code outside supported area", state: 'MA')
      end

      it 'should return failure' do
        result = subject.call(params)
        expect(result.failure?).to eq true
      end
    end

    context 'when product offered in service area' do

      it 'should return success' do
        result = subject.call(params)
        expect(result.success?).to eq true
      end
    end
  end
end
