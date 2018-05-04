require 'rails_helper'

# AcaShopRenewalApplicationConfiguration test cases
module BenefitMarkets
  RSpec.describe Configurations::AcaShopRenewalApplicationConfiguration, type: :model do
    let(:erlst_strt_prior_eff_months) { -3 }
    let(:force_pub_dom) { 15 }
    let(:quiet_per_end) { 20 }

    context "ability to create, validate and persist instances of this class" do
      context "with no arguments" do
        subject { described_class.new }
        let!(:benefit_market) { BenefitMarkets::AcaShopConfiguration.new }

        before(:each) do
          subject.benefit_market = benefit_market
        end
        it "should be valid" do
          subject.validate
          expect(subject).to be_valid
        end

        it "should be benefit market" do
          expect(subject.benefit_market).to be_instance_of(BenefitMarkets::AcaShopConfiguration)
        end
      end
    end
  end
end
