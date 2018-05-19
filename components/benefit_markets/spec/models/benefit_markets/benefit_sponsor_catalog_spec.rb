require 'rails_helper'

module BenefitMarkets
  RSpec.describe BenefitSponsorCatalog, type: :model do
    let(:subject) { described_class.new }

    let(:this_year)               { Date.today.year }
    let(:application_period)      { Date.new(this_year,1,1)..Date.new(this_year,12,31) }
    let(:effective_date)          { Date.new(this_year, 6,1) }
    let(:effective_period)        { effective_date..(effective_date + 1.year - 1.day) }
    let(:open_enrollment_period)  { (effective_date - 1.month)..(effective_date - 1.month + 9.days) }
    let(:probation_period_kinds)  { [:first_of_month, :first_of_month_after_30_days, :first_of_month_after_60_days] }
    let(:service_area)            { BenefitMarkets::Locations::ServiceArea.new }
    let(:sponsor_market_policy)   { BenefitMarkets::MarketPolicies::SponsorMarketPolicy.new }
    let(:member_market_policy)    { BenefitMarkets::MarketPolicies::MemberMarketPolicy.new }
    let(:product_packages)        { [FactoryGirl.build(:benefit_markets_products_product_package)] }


    context "A new model instance" do

     # it { is_expected.to be_mongoid_document }
     # it { is_expected.to have_fields(:effective_date, :effective_period, :open_enrollment_period) }
     # it { is_expected.to have_field(:probation_period_kinds).of_type(Array).with_default_value_of([]) }

     # it { is_expected.to embeds_one(:sponsor_market_policy) }
     # it { is_expected.to embeds_one(:member_market_policy) }
     # it { is_expected.to embeds_many(:benefit_packages) }
     # it { is_expected.to belongs_to(:service_area) }


      let(:params) do
        {
          effective_date: effective_date,
          effective_period: effective_period,
          open_enrollment_period: open_enrollment_period,
          probation_period_kinds: probation_period_kinds,
          service_area: service_area,
          sponsor_market_policy: sponsor_market_policy,
          member_market_policy: member_market_policy,
          product_packages: product_packages,
        }
      end

      context "with no effective_date" do
        subject { described_class.new(params.except(:effective_date)) }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "with no effective_period" do
        subject { described_class.new(params.except(:effective_period)) }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "with no open_enrollment_period" do
        subject { described_class.new(params.except(:open_enrollment_period)) }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "with no probation_period_kinds" do
        subject { described_class.new(params.except(:probation_period_kinds)) }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "with no service_area" do
        subject { described_class.new(params.except(:service_area)) }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "with no sponsor_market_policy" do
        subject { described_class.new(params.except(:sponsor_market_policy)) }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "with no member_market_policy" do
        subject { described_class.new(params.except(:member_market_policy)) }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "with no product_packages" do
        subject { described_class.new(params.except(:product_packages)) }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "with all required arguments" do
        subject { described_class.new(params) }

        it "should be valid" do
          subject.validate
          expect(subject).to be_valid
        end
      end
    end


  end
end
