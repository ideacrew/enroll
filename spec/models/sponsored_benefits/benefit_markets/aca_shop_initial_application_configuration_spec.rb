require 'rails_helper'

# AcaShopInitialApplicationConfiguration test cases
module SponsoredBenefits
  RSpec.describe BenefitMarkets::AcaShopInitialApplicationConfiguration, type: :model do
    let(:pub_due_dom) { 10 }
    let(:quiet_per_end) { 28 }

    context "ability to create, validate and persist instances of this class" do
      context "with no arguments" do
        subject { described_class.new }
        let!(:benefit_market) { SponsoredBenefits::BenefitMarkets::AcaShopConfiguration.new }

        before(:each) do
          subject.benefit_market = benefit_market
        end
        it "should be valid" do
          subject.validate
          expect(subject).to be_valid
        end

        it "should be benefit market" do
          expect(subject.benefit_market).to be_instance_of(SponsoredBenefits::BenefitMarkets::AcaShopConfiguration)
        end
      end
    end
  end
end