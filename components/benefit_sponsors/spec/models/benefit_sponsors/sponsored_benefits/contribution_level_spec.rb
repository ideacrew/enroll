require 'rails_helper'

module BenefitSponsors
  RSpec.describe ::BenefitSponsors::SponsoredBenefits::ContributionLevel, :dbclean => :after_each do
    describe "given nothing" do
      it "requires a display name" do
        subject.valid?
        expect(subject.errors.has_key?(:display_name)).to be_truthy
      end

      it "requires a contribution unit id" do
        subject.valid?
        expect(subject.errors.has_key?(:contribution_unit_id)).to be_truthy
      end

      context 'contribution_factor' do
        let(:contribution_level) { described_class.new({contribution_factor: 0.550000000001}) }

        it 'should return a valid value without float issue' do
          expect(contribution_level.contribution_factor).to eq(0.55)
        end
      end
    end
  end
end
