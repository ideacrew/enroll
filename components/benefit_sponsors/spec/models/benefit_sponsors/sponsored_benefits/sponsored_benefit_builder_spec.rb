require 'rails_helper'

RSpec.describe BenefitSponsors::SponsoredBenefits::SponsoredBenefitBuilder, type: :model, :dbclean => :after_each do
  it "should exist as a class" do
    expect(BenefitSponsors::SponsoredBenefits::SponsoredBenefitBuilder.new).to be_truthy
  end
end
