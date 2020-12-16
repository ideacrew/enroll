require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

module BenefitMarkets
  RSpec.describe Products::ProductPackage, type: :model, dbclean: :after_each do

    let(:this_year)               { TimeKeeper.date_of_record.year }
    # let(:benefit_market_kind)     { :aca_shop }

    let(:benefit_market_catalog)  { FactoryGirl.build(:benefit_markets_benefit_market_catalog) }
    let(:benefit_kind)            { :aca_shop }
    let(:product_kind)            { :health }
    let(:package_kind)            { :single_issuer }
    let(:title)                   { "SafeCo Issuer Health" }
    let(:description)             { "All products offered by a single issuer" }
    let(:products)                { FactoryGirl.build_list(:benefit_markets_products_product, 5) }
    let(:contribution_model)      { FactoryGirl.build(:benefit_markets_contribution_models_contribution_model) }
    let(:pricing_model)           { FactoryGirl.build(:benefit_markets_pricing_models_pricing_model) }


    let(:params) do
        {
          benefit_kind:           benefit_kind,
          product_kind:           product_kind,
          package_kind:           package_kind,
          title:                  title,
          description:            description,
          products:               products,
          application_period:     benefit_market_catalog.application_period,
          contribution_model:     contribution_model,
          pricing_model:          pricing_model,
        }
    end

    context "A new model instance" do

      context "with no arguments" do
        subject { described_class.new }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "without required params" do

        # context "that's missing benefit_market_catalog" do
        #   subject { described_class.new(params.except(:benefit_market_catalog)) }

        #   it "should be invalid" do
        #     subject.validate
        #     expect(subject).to_not be_valid
        #     expect(subject.errors[:benefit_market_catalog]).to include("can't be blank")
        #   end
        # end

        context "that's missing title" do
          subject { described_class.new(params.except(:title)) }

          it "should be invalid" do
            subject.validate
            expect(subject).to_not be_valid
            expect(subject.errors[:title]).to include("can't be blank")
          end
        end

        context "that's missing product_kind" do
          subject { described_class.new(params.except(:product_kind)) }

          it "should be invalid" do
            subject.validate
            expect(subject).to_not be_valid
            expect(subject.errors[:product_kind]).to include("can't be blank")
          end
        end

        context "that's missing kind" do
          subject { described_class.new(params.except(:package_kind)) }

          it "should be invalid" do
            subject.validate
            expect(subject).to_not be_valid
            expect(subject.errors[:package_kind]).to include("can't be blank")
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

    context "Comparing Product Packages" do
      let(:base_product_package)      { described_class.new(**params) }

      context "and they are the same" do
        let(:compare_product_package) { described_class.new(**params) }

        it "they should be different instances" do
          expect(base_product_package.id).to_not eq compare_product_package.id
        end

        it "should match" do
          expect(base_product_package <=> compare_product_package).to eq 0
          expect(base_product_package.attributes.except('_id')).to eq compare_product_package.attributes.except('_id')
        end
      end

      context "and the attributes are different" do
        let(:compare_product_package)              { described_class.new(**params) }

        before { compare_product_package.product_kind = :dental }

        it "should not match" do
          expect(base_product_package).to_not eq compare_product_package
        end

        it "the base_product_package should be less than the compare_product_package" do
          expect(base_product_package <=> compare_product_package).to eq -1
        end
      end

      context "and the product_packages are different" do
        let(:compare_product_package)     { described_class.new(**params) }
        let(:new_product)                 { FactoryGirl.build(:benefit_markets_products_product) }

        before { compare_product_package.products << new_product }

        it "should not match" do
          expect(base_product_package).to_not eq compare_product_package
        end

        it "the base_product_package should be lest than the compare_product_package" do
          expect(base_product_package <=> compare_product_package).to eq -1
        end
      end
    end

    context 'for one carrier product package' do
      include_context 'setup benefit market with market catalogs and product packages'
      include_context 'setup initial benefit application'

      let!(:one_issuer_product_package) {initial_application.benefit_sponsor_catalog.product_packages.select {|pp| pp.package_kind == :single_issuer}}
      let!(:all_products) do
        products = one_issuer_product_package.map(&:products).flatten
        products[2].update_attributes!(hios_id: '52842DC0400016-01')
        BenefitMarkets::Products::Product.all.where(id: products[2].id).first.update_attributes!(hios_id: '52842DC0400016-01')
        products[3].update_attributes!(hios_id: '52842DC0400017-01')
        BenefitMarkets::Products::Product.all.where(id: products[3].id).first.update_attributes!(hios_id: '52842DC0400016-01')
        products
      end

      let!(:all_products_update) do
        cost_counter = 50
        all_products.flatten.each do |p|
          product = BenefitMarkets::Products::Product.all.where(id: p.id).first
          product.premium_tables.each do |pt|
            pt.premium_tuples.delete_all
            pt.premium_tuples.create(age: 20, cost: cost_counter)
            pt.premium_tuples.create(age: 21, cost: cost_counter + 10)
            pt.premium_tuples.create(age: 22, cost: cost_counter + 20)
            pt.premium_tuples.create(age: 23, cost: cost_counter + 30)
            pt.save!
          end
          cost_counter += 50
          product.save!
        end
      end

      it 'should return lowest_cost_product from selected carrier' do
        result = one_issuer_product_package.first.lowest_cost_product(TimeKeeper.date_of_record, ['52842'])
        lowest_product = all_products.select{|p| p.hios_id == '52842DC0400016-01'}.first
        expect(result).to eq lowest_product
      end
    end
  end
end
