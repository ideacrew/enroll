require 'rails_helper'

module BenefitMarkets
  RSpec.describe Products::Product, type: :model do

    let(:this_year)               { TimeKeeper.date_of_record.year }
    let(:benefit_market_kind)     { :aca_shop }
    let(:application_period)      { Date.new(this_year, 1, 1)..Date.new(this_year, 12, 31) }
    let(:hbx_id)                  { "6262626262" }
    let(:issuer_profile_urn)      { "urn:openhbx:terms:v1:organization:name#safeco" }
    let(:title)                   { "SafeCo Active Life $0 Deductable Premier" }
    let(:description)             { "Highest rated and highest value" }

    let(:params) do 
        {
          benefit_market_kind: benefit_market_kind,
          hbx_id: hbx_id,
          issuer_profile_urn: issuer_profile_urn,
          title: title,
          description: description,
        }
    end

    context "A new HealthProduct instance" do

      context "that's missing required params" do

        context "with no arguments" do
          # binding.pry
          subject { described_class.new }

          it "should not be valid" do
            subject.validate
            expect(subject).to_not be_valid
          end
        end


        context "without benefit_market_kind" do
          subject { described_class.new(params.except(:benefit_market_kind)) }

          it "it should be invalid" do
            subject.validate
            expect(subject).to_not be_valid
            expect(subject.errors[:benefit_market_kind]).to include("can't be blank")
          end
        end

        context "without application_period" do
          subject { described_class.new(params.except(:application_period)) }

          it "should be invalid" do
            subject.validate
            expect(subject).to_not be_valid
            expect(subject.errors[:application_period]).to include("can't be blank")
          end
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
