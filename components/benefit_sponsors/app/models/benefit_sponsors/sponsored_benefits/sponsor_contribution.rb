module BenefitSponsors
  class SponsoredBenefits::SponsorContribution
    include Mongoid::Document

    embeds_many :contribution_levels,
                class_name: "BenefitSponsors::SponsoredBenefits::ContributionLevel"
  end
end
