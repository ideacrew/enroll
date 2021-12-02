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

    let(:params) do
      {
        products: products,
        dental_products: [],
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
      let(:ped_dental_products) {[double]}
      let(:params) do
        {
          products: products,
          dental_products: ped_dental_products,
          family: family,
          effective_date: effective_date,
          rating_area_id: rating_area_id
        }
      end

      let(:second_lowest_dental_premium) { 100 }

      before do
        person.update_attributes(dob: TimeKeeper.date_of_record - 15.years)
        allow(subject).to receive(:second_lowest_dental_product_premium).and_return second_lowest_dental_premium
      end

      context 'when product does not covers pediatric' do

        context 'when person age > 18' do

          before do
            person.update_attributes(dob: TimeKeeper.date_of_record - 25.years)
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

        context 'when person age < 18' do
          before do
            person.update_attributes(dob: TimeKeeper.date_of_record - 15.years)
          end

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

  describe 'valid params with 2 member household' do
    let(:person) { FactoryBot.create(:person, :with_consumer_role) }
    let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}

    let!(:child_person) do
      p3 = FactoryBot.create(:person, :with_consumer_role, first_name: 'Person3', dob: TimeKeeper.date_of_record - 16.years)
      person.ensure_relationship_with(p3, 'child')
      p3
    end
    let!(:family_member3) { FactoryBot.create(:family_member, person: child_person, family: family)}
    let!(:ped_dental_products) do
      FactoryBot.create_list(:benefit_markets_products_dental_products_dental_product, 5, :with_issuer_profile, :with_qhp, pediatric_ehb: 0.9943, rating_method: 'Age-Based Rates')
      counter = 10
      rating_area_id = ::BenefitMarkets::Products::Product.all.first.premium_tables.first.rating_area_id
      ::BenefitMarkets::Products::Product.dental_products.each do |p|
        p.premium_tables.each do |pt|
          pt.update_attributes(rating_area_id: rating_area_id)
          pt.premium_tuples.each do |premium_tuple|
            premium_tuple.update_attributes!(cost: counter + premium_tuple.age)
          end
          counter += 10
        end
      end
      ::BenefitMarkets::Products::Product.all.dental_products
    end

    let(:product) { products.first }
    let(:premium_table) { product.premium_tables.first }
    let(:rating_area_id) { premium_table.rating_area_id }
    let(:effective_date) { TimeKeeper.date_of_record }

    context 'for slcsp_type health_and_ped_dental' do
      context 'when health product does covers pediatric' do
        let(:params) do
          {
            products: products,
            dental_products: ped_dental_products,
            family: family,
            effective_date: effective_date,
            rating_area_id: rating_area_id,
            slcsp_type: :health_and_ped_dental
          }
        end

        let(:second_lowest_dental_premium) { 100 }

        let!(:products) do
          FactoryBot.create_list(:benefit_markets_products_health_products_health_product, 5, :silver, :with_qhp)
          counter = 100
          rating_area_id = ::BenefitMarkets::Products::Product.all.first.premium_tables.first.rating_area_id
          ::BenefitMarkets::Products::Product.health_products.each do |p|
            p.premium_tables.each do |pt|
              pt.update_attributes(rating_area_id: rating_area_id)
              pt.premium_tuples.each do |premium_tuple|
                cost = premium_tuple.cost
                premium_tuple.update_attributes!(cost: cost + counter + premium_tuple.age)
              end
              counter += 100
            end
          end
          health_products = ::BenefitMarkets::Products::Product.all.health_products
          health_products
        end

        before do
          allow(subject).to receive(:second_lowest_dental_product_premium).and_return second_lowest_dental_premium
        end

        context 'when person age < 18' do
          it 'should adjust premium value' do
            result = subject.call(params)
            expect(result.success[child_person.hbx_id].first).to eq(
              {
                :cost => 314.2 + second_lowest_dental_premium,
                :product_id => BSON::ObjectId(product.id),
                :member_identifier => child_person.hbx_id,
                :monthly_premium => 314.2 + second_lowest_dental_premium
              }
            )
          end
        end
      end
    end

    context 'for slcsp_type health_and_dental' do
      context 'when health product does covers pediatric' do
        let!(:products) do
          FactoryBot.create_list(:benefit_markets_products_health_products_health_product, 5, :silver, :with_qhp)
          counter = 100
          rating_area_id = ::BenefitMarkets::Products::Product.all.first.premium_tables.first.rating_area_id
          ::BenefitMarkets::Products::Product.health_products.each do |p|
            p.premium_tables.each do |pt|
              pt.update_attributes(rating_area_id: rating_area_id)
              pt.premium_tuples.each do |premium_tuple|
                cost = premium_tuple.cost
                premium_tuple.update_attributes!(cost: cost + counter + premium_tuple.age)
              end
              counter += 100
            end
          end
          health_products = ::BenefitMarkets::Products::Product.all.health_products
          health_products.first.qhp.qhp_benefits.create!(benefit_type_code: 'Dental Check-Up for Children', is_benefit_covered: 'Covered')
          health_products.first.qhp.qhp_benefits.create!(benefit_type_code: 'Basic Dental Care - Child', is_benefit_covered: 'Covered')
          health_products.first.qhp.qhp_benefits.create!(benefit_type_code: 'Major Dental Care - Child', is_benefit_covered: 'Covered')
          health_products
        end

        let(:params) do
          {
            products: products,
            dental_products: ped_dental_products,
            family: family,
            effective_date: effective_date,
            rating_area_id: rating_area_id,
            slcsp_type: :health_and_dental
          }
        end

        context 'when person age < 18' do
          it 'should not adjust premium value' do
            result = subject.call(params)
            expect(result.success[child_person.hbx_id].first).to eq(
              {
                :cost => 314.2,
                :product_id => BSON::ObjectId(product.id),
                :member_identifier => child_person.hbx_id,
                :monthly_premium => 314.2
              }
            )
          end
        end
      end
    end
  end
end