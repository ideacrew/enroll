require "rails_helper"

module BenefitMarkets
  RSpec.describe ContributionModels::ContributionModel do
    describe "given nothing" do
      it "is invalid" do
        expect(subject.valid?).to be_falsey
      end

      it "is missing a name" do
        subject.valid?
        expect(subject.errors.has_key?(:name)).to be_truthy
      end

      it "is missing contribution models" do
        subject.valid?
        expect(subject.errors.has_key?(:contribution_units)).to be_truthy
      end

      it "is missing member relationships" do
        subject.valid?
        expect(subject.errors.has_key?(:member_relationships)).to be_truthy
      end

      it "is a contribution value kind" do
        subject.valid?
        expect(subject.errors.has_key?(:contribution_value_kind)).to be_truthy
      end
    end
  end
end
