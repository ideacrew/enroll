require 'rails_helper'

module BenefitMarkets
  RSpec.describe Products::Product, type: :model do

    let(:this_year)           { TimeKeeper.date_of_record.year }
    let(:benefit_market_kind) { :aca_shop }
    let(:application_period)  { Date.new(this_year, 1, 1)..Date.new(this_year, 12, 31) }
    let(:hbx_id)              { "6262626262" }
    let(:issuer_profile_urn)  { "urn:openhbx:terms:v1:organization:name#safeco" }
    let(:title)               { "SafeCo Active Life $0 Deductable Premier" }
    let(:description)         { "Highest rated and highest value" }

    let(:rating_area)         { BenefitMarkets::Locations::RatingArea.new }
    let(:quarter_1)           { Date.new(this_year, 1, 1)..Date.new(this_year, 3, 31) }
    let(:premium_q1_age_20)   { BenefitMarkets::Products::PremiumTuple.new(age: 20, cost: 201) }
    let(:premium_q1_age_30)   { BenefitMarkets::Products::PremiumTuple.new(age: 30, cost: 301) }
    let(:premium_q1_age_40)   { BenefitMarkets::Products::PremiumTuple.new(age: 40, cost: 401) }
    let(:premium_table_q1)    { BenefitMarkets::Products::PremiumTable.new(
                                  effective_period: quarter_1,
                                  rating_area: rating_area,
                                  premium_tuples: [premium_q1_age_20, premium_q1_age_30, premium_q1_age_40],
                                ) }

    let(:quarter_2)           { Date.new(this_year, 4, 1)..Date.new(this_year, 6, 30) }
    let(:premium_q2_age_20)   { BenefitMarkets::Products::PremiumTuple.new(age: 20, cost: 202) }
    let(:premium_q2_age_30)   { BenefitMarkets::Products::PremiumTuple.new(age: 30, cost: 302) }
    let(:premium_q2_age_40)   { BenefitMarkets::Products::PremiumTuple.new(age: 40, cost: 402) }
    let(:premium_table_q1)    { BenefitMarkets::Products::PremiumTable.new(
                                  effective_period: quarter_2,
                                  rating_area: rating_area,
                                  premium_tuples: [premium_q2_age_20, premium_q2_age_30, premium_q2_age_40],
                                ) }

    let(:premium_tables)      { [premium_table_q1] }

    let(:params) do
        {
          benefit_market_kind:  benefit_market_kind,
          application_period:   application_period,
          hbx_id:               hbx_id,
          issuer_profile_urn:   issuer_profile_urn,
          title:                title,
          description:          description,
          premium_tables:       premium_tables,
        }
    end

    context "A new HealthProduct instance" do

      context "with no arguments" do
        subject { described_class.new }

        it "should not be valid" do 
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "without required params" do
        context "that's missing a benefit_market_kind" do
          subject { described_class.new(params.except(:benefit_market_kind)) }

          it "it should be invalid" do
            subject.validate
            expect(subject).to_not be_valid
            expect(subject.errors[:benefit_market_kind]).to include("can't be blank")
          end
        end

        context "that's missing an application_period" do
          subject { described_class.new(params.except(:application_period)) }

          it "should be invalid" do
            subject.validate
            expect(subject).to_not be_valid
            expect(subject.errors[:application_period]).to include("can't be blank")
          end
        end

        context "that's missing an hbx_id" do
          subject { described_class.new(params.except(:hbx_id)) }

          it "should be invalid" do
            subject.validate
            expect(subject).to_not be_valid
            expect(subject.errors[:hbx_id]).to include("can't be blank")
          end
        end

        context "that's missing a title" do
          subject { described_class.new(params.except(:title)) }

          it "should be invalid" do
            subject.validate
            expect(subject).to_not be_valid
            expect(subject.errors[:title]).to include("can't be blank")
          end
        end
      end

      context "with invalid arguments" do
        context "and benefit_market_kind is invalid" do
          let(:invalid_benefit_market_kind)  { :flea_market }

          subject { described_class.new(params.except(:benefit_market_kind).merge({benefit_market_kind: invalid_benefit_market_kind})) }

          it "should not be valid" do
            subject.validate
            expect(subject).to_not be_valid
            expect(subject.errors[:benefit_market_kind]).to include("#{invalid_benefit_market_kind} is not a valid benefit market kind")
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

    context "An open file in SERFF template format" do
      context "and the contents are Qualified Health Plans" do
      end

      context "and the contents are QHP service areas" do
      end

      context "and the contents are QHP rate tables" do
      end

      context "and the contents are Qualified Dental Plans" do
      end

      context "and the contents are QDP rate tables" do
      end
    end


  end
end
