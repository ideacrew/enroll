module BenefitSponsors
  module SponsoredBenefits
    class ContributionLevel
    include Mongoid::Document
    include Mongoid::Timestamps


    embedded_in :sponsor_contribution,
                class_name: "BenefitSponsors::SponsoredBenefits::SponsorContribution"

    end
  end
end
