# frozen_string_literal: true
require 'rails_helper'
RSpec.describe BenefitSponsors::SponsoredBenefits::SponsorContribution, type: :model, :dbclean => :after_each do
  it "should exists as a class" do
    expect(BenefitSponsors::SponsoredBenefits::SponsorContribution.new).to be_truthy
  end
end