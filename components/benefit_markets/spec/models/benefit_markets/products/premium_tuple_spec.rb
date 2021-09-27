require 'rails_helper'

module BenefitMarkets
  RSpec.describe Products::PremiumTuple, type: :model do


    let(:age)   { 25 }
    let(:cost)  { 210.32 }

    let(:params) do
      {
        age:  age,
        cost: cost,
      }
    end

    context "A new PremiumTuple instance" do

      context "with no arguments" do
        subject { described_class.new }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "without required params" do
        context "that's missing age" do
          subject { described_class.new(params.except(:age)) }

          it "should be invalid" do
            subject.validate
            expect(subject).to_not be_valid
            expect(subject.errors[:age]).to include("can't be blank")
          end
        end

        context "that's missing cost" do
          subject { described_class.new(params.except(:cost)) }

          it "should be invalid" do
            subject.validate
            expect(subject).to_not be_valid
            expect(subject.errors[:cost]).to include("can't be blank")
          end
        end

      end

      context "with all valid params" do
        subject { described_class.new(params) }

        it "should be valid" do
          subject.validate
          expect(subject).to be_valid
        end
      end
    end

    context "Comparing PremiumTuples" do
      let(:base_premium_tuple)      { described_class.new(**params) }

      context "and they are the same" do
        let(:compare_premium_tuple) { described_class.new(**params) }

        it "they should be different instances" do
          expect(base_premium_tuple.id).to_not eq compare_premium_tuple.id
        end

        it "should match" do
          expect(base_premium_tuple <=> compare_premium_tuple).to eq 0
        end
      end

      context "and the attributes are different" do
        let(:compare_premium_tuple) { described_class.new(**params) }

        before { compare_premium_tuple.age = (base_premium_tuple.age + 2.years) }

        it "should not match" do
          expect(base_premium_tuple).to_not eq compare_premium_tuple
        end

        it "the base_premium_tuple should be less than the compare_premium_tuple" do
          expect(base_premium_tuple <=> compare_premium_tuple).to eq(-1)
        end
      end
    end

    context 'qhp_premium_table' do
      # let(:qhp) { FactoryBot.create(:qhp, qhp_premium_tables: [qhp_premium_table], standard_component_id: product.hios_base_id) }
      # let(:qhp_premium_table) { FactoryBot.build(:qhp_premium_table, plan_id: product.hios_base_id) }

      # let(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product) }
      context 'age_based_rating' do
        let(:product) { double('Product', age_based_rating?: true) }
        let(:premium_tuple) { ::BenefitMarkets::Products::PremiumTuple.new }

        before { allow(premium_tuple).to receive(:product).and_return(product) }

        it 'should return nil' do
          expect(premium_tuple.qhp_premium_table).to be_nil
        end
      end

      context 'family_based_rating' do
        let!(:qhp) do
          double(
            'Products::Qhp',
            qhp_premium_tables: [qhp_premium_table],
            standard_component_id: product.hios_base_id,
            active_year: product.active_year
          )
        end
        let!(:qhp_premium_table) do
          double(
            'QhpPremiumTable',
            plan_id: product.hios_base_id,
            rate_area_id: 'rating_area',
            effective_date: TimeKeeper.date_of_record.beginning_of_year,
            expiration_date: TimeKeeper.date_of_record.end_of_year,
            age_number: '20',
            primary_enrollee: '10',
            couple_enrollee: '20',
            couple_enrollee_one_dependent: '25',
            couple_enrollee_two_dependent: '30',
            couple_enrollee_many_dependent: '40',
            primary_enrollee_one_dependent: '15',
            primary_enrollee_two_dependent: '20',
            primary_enrollee_many_dependent: '30'
          )
        end

        let(:product) { FactoryBot.build(:benefit_markets_products_dental_products_dental_product) }
        let(:premium_table) { FactoryBot.build(:benefit_markets_products_premium_table) }
        let(:premium_tuple) { FactoryBot.build(:benefit_markets_products_premium_tuple) }

        before do
          allow(premium_tuple).to receive(:qhp_product).and_return(qhp)
          allow(premium_tuple).to receive(:product).and_return(product)
          allow(premium_tuple).to receive(:premium_table).and_return(premium_table)
          allow(premium_table).to receive(:exchange_provided_code).and_return(qhp_premium_table.rate_area_id)

          product.update(rating_method: 'Family-Tier Rates')
        end

        it 'should return correct values' do
          qhp_pt = premium_tuple.qhp_premium_table

          expect(qhp_pt.primary_enrollee).to eq premium_tuple.primary_enrollee
          expect(qhp_pt.couple_enrollee).to eq premium_tuple.couple_enrollee
          expect(qhp_pt.couple_enrollee_one_dependent).to eq premium_tuple.couple_enrollee_one_dependent
          expect(qhp_pt.couple_enrollee_two_dependent).to eq premium_tuple.couple_enrollee_two_dependent
          expect(qhp_pt.couple_enrollee_many_dependent).to eq premium_tuple.couple_enrollee_many_dependent
          expect(qhp_pt.primary_enrollee_one_dependent).to eq premium_tuple.primary_enrollee_one_dependent
          expect(qhp_pt.primary_enrollee_two_dependent).to eq premium_tuple.primary_enrollee_two_dependent
          expect(qhp_pt.primary_enrollee_many_dependent).to eq premium_tuple.primary_enrollee_many_dependent
        end

      end
    end



  end
end
