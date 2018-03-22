require "rails_helper"

module BenefitSponsors
  describe ContributionModels::ContributionModel do
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
    end
  end
end
