require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

module BenefitSponsors
  RSpec.describe BenefitPackages::BenefitPackage, type: :model, :dbclean => :after_each do

    include_context "setup benefit market with market catalogs and product packages"
    include_context "setup initial benefit application"

    let(:title)                 { "Generous BenefitPackage - 2018"}
    let(:probation_period_kind) { :first_of_month_after_30_days }

    let(:params) do
      {
        title: title,
        probation_period_kind: probation_period_kind,
      }
    end


    context "A new model instance" do
      it { is_expected.to be_mongoid_document }
      it { is_expected.to have_field(:title).of_type(String).with_default_value_of("")}
      it { is_expected.to have_field(:description).of_type(String).with_default_value_of("")}
      it { is_expected.to have_field(:probation_period_kind).of_type(Symbol)}
      it { is_expected.to have_field(:is_default).of_type(Mongoid::Boolean).with_default_value_of(false)}
      it { is_expected.to have_field(:is_active).of_type(Mongoid::Boolean).with_default_value_of(true)}
      it { is_expected.to have_field(:predecessor_id).of_type(BSON::ObjectId)}
      it { is_expected.to embed_many(:sponsored_benefits)}
      it { is_expected.to be_embedded_in(:benefit_application)}


      context "with no arguments" do
        subject { described_class.new }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "with no title" do
        subject { described_class.new(params.except(:title)) }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "with no probation_period_kind" do
        subject { described_class.new(params.except(:probation_period_kind)) }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "with all required arguments" do
        subject { described_class.new(params) }


        context "and all arguments are valid" do
          it "should be valid" do
            subject.validate
            expect(subject).to be_valid
          end
        end
      end
    end


    describe ".renew" do
      context "when passed renewal benefit package to current benefit package for renewal" do
        let(:renewal_benefit_sponsor_catalog) { benefit_sponsorship.benefit_sponsor_catalog_for(renewal_effective_date) }
        let(:renewal_application)             { initial_application.renew(renewal_benefit_sponsor_catalog) }
        let!(:renewal_benefit_package)        { renewal_application.benefit_packages.build }

        before do
          current_benefit_package.renew(renewal_benefit_package)
        end

        it "should have valid applications" do
          initial_application.validate
          renewal_application.validate
          expect(initial_application).to be_valid
          expect(renewal_application).to be_valid
        end

        it "should renew benefit package" do
          expect(renewal_benefit_package).to be_present
          expect(renewal_benefit_package.title).to eq current_benefit_package.title
          expect(renewal_benefit_package.description).to eq current_benefit_package.description
          expect(renewal_benefit_package.probation_period_kind).to eq current_benefit_package.probation_period_kind
          expect(renewal_benefit_package.is_default).to eq  current_benefit_package.is_default
        end

        it "should renew sponsored benefits" do
          expect(renewal_benefit_package.sponsored_benefits.size).to eq current_benefit_package.sponsored_benefits.size
        end

        it "should reference to renewal product package" do
          renewal_benefit_package.sponsored_benefits.each_with_index do |sponsored_benefit, i|
            current_sponsored_benefit = current_benefit_package.sponsored_benefits[i]
            expect(sponsored_benefit.product_package).to eq renewal_benefit_sponsor_catalog.product_packages.by_package_kind(current_sponsored_benefit.product_package_kind).by_product_kind(current_sponsored_benefit.product_kind)[0]
          end
        end

        it "should attach renewal reference product" do
          renewal_benefit_package.sponsored_benefits.each_with_index do |sponsored_benefit, i|
            current_sponsored_benefit = current_benefit_package.sponsored_benefits[i]
            expect(sponsored_benefit.reference_product).to eq current_sponsored_benefit.reference_product.renewal_product
          end
        end

        it "should renew sponsor contributions" do
          renewal_benefit_package.sponsored_benefits.each_with_index do |sponsored_benefit, i|
            expect(sponsored_benefit.sponsor_contribution).to be_present

            current_sponsored_benefit = current_benefit_package.sponsored_benefits[i]
            current_sponsored_benefit.sponsor_contribution.contribution_levels.each_with_index do |current_contribution_level, i|
              new_contribution_level = sponsored_benefit.sponsor_contribution.contribution_levels[i]
              expect(new_contribution_level.is_offered).to eq current_contribution_level.is_offered
              expect(new_contribution_level.contribution_factor).to eq current_contribution_level.contribution_factor
            end
          end
        end

        it "should renew pricing determinations" do
        end
      end
    end

    describe '.is_renewal_benefit_available?' do
    end

    describe '.sponsored_benefit_for' do
    end

    describe '.assigned_census_employees_on' do
    end

    describe '.renew_employee_benefits' do
      include_context "setup employees with benefits"

    end
  end
end
