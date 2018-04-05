require 'rails_helper'

module BenefitMarkets
  RSpec.describe BenefitMarketCatalog, type: :model do

    let(:benefit_market_kind)       { :aca_shop }
    let(:today)                     { Date.today }

    let(:title)                     { "Benefit Buddy's SHOP Employer Benefit Market" }
    let(:description)               { "As an eligible employer, you may shop, select, and elect contribution amounts on \
                                      benefit products that you make available for your employees to purchase." }
    let(:benefit_market)            { BenefitMarkets::BenefitMarket.new(kind: benefit_market_kind)  }
    let(:application_interval_kind) { :monthly }
    let(:application_period)        { Date.new(today.year, 1, 1)..Date.new(today.year, 12, 31) }
    let(:probation_period_kinds)    { [:first_of_month, :first_of_month_after_30_days, :first_of_month_after_60_days] }


    context "A new model instance" do
      let(:params) do 
        {
          benefit_market: benefit_market,
          application_interval_kind: application_interval_kind,
          application_period: application_period,
          probation_period_kinds: probation_period_kinds,
          title: title,
          description: description,
        }
      end

      context "with no benefit_market" do
        subject { described_class.new(params.except(:benefit_market)) }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "with no application_interval_kind" do
        subject { described_class.new(params.except(:application_interval_kind)) }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "with no application_period" do
        subject { described_class.new(params.except(:application_period)) }

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

      context "with all required arguments" do
        subject { described_class.new(params) }

        context "and all arguments are valid", dbclean: :after_each do

          it "should be valid" do
            subject.validate
            expect(subject).to be_valid
          end

          it "should save and be findable" do
            expect(subject.save!).to eq true
            expect(BenefitMarkets::BenefitMarketCatalog.find(subject.id)).to eq subject
          end
        end
      end
    end

  end
end
