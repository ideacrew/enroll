require 'rails_helper'

# AcaShopInitialApplicationConfiguration test cases
module BenefitMarkets
  RSpec.describe Configurations::AcaShopInitialApplicationConfiguration, type: :model do
    let(:pub_due_dom) { 10 }
    let(:quiet_per_end) { 28 }

    context "ability to create, validate and persist instances of this class" do
      context "with no arguments" do
        subject { described_class.new }
        let!(:configuration) { BenefitMarkets::AcaShopConfiguration.new }

        before(:each) do
          subject.configuration = configuration
        end
        it "should be valid" do
          subject.validate
          expect(subject).to be_valid
        end

        it "should be benefit market" do
          expect(subject.configuration).to be_instance_of(BenefitMarkets::AcaShopConfiguration)
        end
      end
    end
  end
end
