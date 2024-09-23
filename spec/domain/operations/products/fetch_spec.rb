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

  describe 'for non-rating area site' do
    before do
      allow(EnrollRegistry[:enroll_app].setting(:geographic_rating_area_model)).to receive(:item).and_return('single')
      allow(EnrollRegistry[:enroll_app].setting(:rating_areas)).to receive(:item).and_return('single')
    end

    let(:person) { FactoryBot.create(:person, :with_consumer_role) }
    let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}

    let!(:person2) do
      p2 = FactoryBot.create(:person, :with_consumer_role, first_name: 'Person2')
      person.ensure_relationship_with(p2, 'spouse')
      p2
    end
    let!(:family_member2) { FactoryBot.create(:family_member, person: person2, family: family)}

    let(:effective_date) { TimeKeeper.date_of_record }
    let(:params) do
      {
        family: family,
        effective_date: effective_date
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

    before do
      ::BenefitMarkets::Products::ProductRateCache.initialize_rate_cache!
    end

    context 'with one member having addresses in different state' do

      before do
        family.primary_applicant.person.addresses.first.update_attributes(state: 'dc')
        family.family_members.where(is_primary_applicant: false).each do |f_member|
          f_member.person.addresses.each { |addr| addr.update_attributes!(kind: 'home', state: 'co', zip: "41001")}
        end

        @result = subject.call(params)
      end

      it 'should return true' do
        expect(@result.success?).to be_truthy
      end

      it "should fetch products for primary applicant's address" do
        expect(@result.success.count).to eq 1
      end

      it "should fetch products mapped to all members" do
        expect(@result.success.keys.flatten.count).to eq family.active_family_members.count
      end
    end

    context 'with all members having addresses in different states' do

      before do
        family.primary_applicant.person.addresses.first.update_attributes(state: 'pa')
        family.family_members.where(is_primary_applicant: false).each do |f_member|
          f_member.person.addresses.each { |addr| addr.update_attributes!(kind: 'home', state: 'co', zip: "41001")}
        end

        @result = subject.call(params)
      end

      it 'should return true' do
        expect(@result.success?).to be_truthy
      end

      it "should fetch products for primary applicant's address" do
        expect(@result.success.count).to eq 1
      end
    end

    context 'with one member being inactive with no address' do

      before do
        family.family_members.last.update_attributes(is_active: false)
        family.family_members.where(is_active: false).each do |f_member|
          f_member.person.addresses.each { |addr| addr.update_attributes!([])}
        end

        @result = subject.call(params)
      end

      it 'should return true' do
        expect(@result.success?).to be_truthy
      end
    end

    context 'with one member being active with no address' do

      before do
        family.family_members.last.person.addresses = []
        family.family_members.last.person.save!

        @result = subject.call(params)
      end

      it 'should return false' do
        expect(@result.success?).to be_falsy
      end
    end
  end

  describe 'for rating area site' do
    before do
      allow(EnrollRegistry[:enroll_app].setting(:rating_areas)).to receive(:item).and_return('county')
    end

    let(:person) { FactoryBot.create(:person, :with_consumer_role) }
    let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}

    let!(:person2) do
      p2 = FactoryBot.create(:person, :with_consumer_role, first_name: 'Person2')
      person.ensure_relationship_with(p2, 'spouse')
      p2
    end
    let!(:family_member2) { FactoryBot.create(:family_member, person: person2, family: family)}

    let(:effective_date) { TimeKeeper.date_of_record }
    let(:params) do
      {
        family: family,
        effective_date: effective_date
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

    context 'with one member having addresses in different state' do

      before do
        family.primary_applicant.person.addresses.first.update_attributes(state: 'me', zip: '04007', county: 'york')
        family.family_members.where(is_primary_applicant: false).each do |f_member|
          f_member.person.addresses.each { |addr| addr.update_attributes!(kind: 'home', state: 'co', zip: "41001")}
        end
        BenefitMarkets::Locations::RatingArea.update_all(covered_states: ['ME'])
        ::BenefitMarkets::Locations::CountyZip.all.update_all(county_name: 'york',zip: "04007", state: "ME")
        ::BenefitMarkets::Products::ProductRateCache.initialize_rate_cache!
        @result = subject.call(params)
      end

      it 'should return true' do
        expect(@result.success?).to be_truthy
      end

      it "should fetch products for primary applicant's address" do
        expect(@result.success.count).to eq 1
      end

      it "should fetch products mapped to all members" do
        expect(@result.success.keys.flatten.count).to eq family.active_family_members.count
      end
    end

    context 'with all members having addresses in different states' do

      before do
        family.primary_applicant.person.addresses.first.update_attributes(state: 'pa')
        family.family_members.where(is_primary_applicant: false).each do |f_member|
          f_member.person.addresses.each { |addr| addr.update_attributes!(kind: 'home', state: 'co', zip: "41001")}
        end

        BenefitMarkets::Locations::RatingArea.update_all(covered_states: ['ME'])
        ::BenefitMarkets::Locations::CountyZip.all.update_all(county_name: 'york',zip: "04007", state: "ME")
        @result = subject.call(params)
      end

      it 'should return false' do
        expect(@result.failure?).to be_truthy
      end
    end
  end
end
