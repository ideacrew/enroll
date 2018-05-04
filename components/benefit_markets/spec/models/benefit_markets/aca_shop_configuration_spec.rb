require 'rails_helper'

# AcaShopApplicationConfiguration test cases
module BenefitMarkets
  RSpec.describe Configurations::AcaShopConfiguration, type: :model do
    let(:ee_ct_max) { 50 }
    let(:binder_due_dom) { 23 }

    context "ability to create, validate and persist instances of this class" do
      context "with no arguments" do
        subject { described_class.new }

        it "should be valid" do
          subject.validate
          expect(subject).to be_valid
        end
      end
    end
  end
end
