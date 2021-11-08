# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::Products::FetchSilverProductPremiums, dbclean: :after_each do

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

    let!(:products) do
      FactoryBot.create_list(:benefit_markets_products_health_products_health_product, 1, :silver, :with_qhp)
      ::BenefitMarkets::Products::Product.all
    end

    let(:product) { products.first }

    let(:premium_table) { products.first.premium_tables.first }
    let(:rating_area_id) { premium_table.rating_area_id }

    let(:effective_date) { TimeKeeper.date_of_record }

    # let(:product_premium) do
    #   age = person.age_on(effective_date)
    #   pt = product.premium_tables.first
    #   tuple = pt.premium_tuples.where(age: age).first
    #   tuple.cost * product.ehb
    # end

    let(:params) do
      {
        products: products,
        family: family,
        effective_date: effective_date,
        rating_area_id: rating_area_id
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
    end

    context 'when tuple does not exist for given age' do

      before :each do
        person.update_attributes(dob: TimeKeeper.date_of_record - 70.years)
      end

      it 'should return success' do
        result = subject.call(params)
        expect(result.success?).to eq true
      end

      it 'should return a hash of products' do
        result = subject.call(params)
        expect(result.value!.is_a?(Hash)).to eq true
        expect(result.value!.values.present?).to eq true
      end
    end

    context 'with adjust_pediatric_premium set to true' do
      let(:params) do
        {
          products: products,
          family: family,
          effective_date: effective_date,
          rating_area_id: rating_area_id,
          adjust_pediatric_premium: true
        }
      end

      let(:second_lowest_dental_premium) { 100 }

      before do
        allow(subject).to receive(:second_lowest_dental_product_premium).and_return second_lowest_dental_premium
      end

      context 'when product does not covers pediatric' do

        it 'should adjust premium value' do
          result = subject.call(params)
          expect(result.value!).to eq({
                                        person.hbx_id => [
                                          {
                                            :cost => 198.86 + second_lowest_dental_premium,
                                            :product_id => BSON::ObjectId(product.id),
                                            :member_identifier => person.hbx_id,
                                            :monthly_premium => 198.86 + second_lowest_dental_premium
                                          }
                                        ]
                                      })
        end
      end

      context 'when product covers pediatric' do

        before :each do
          allow_any_instance_of(product.class).to receive(:covers_pediatric_dental?).and_return true
        end

        it 'should not adjust premium value' do
          result = subject.call(params)
          expect(result.value!).to eq({
                                        person.hbx_id => [
                                          {
                                            :cost => 198.86,
                                            :product_id => BSON::ObjectId(product.id),
                                            :member_identifier => person.hbx_id,
                                            :monthly_premium => 198.86
                                          }
                                        ]
                                      })
        end
      end
    end
  end
end
