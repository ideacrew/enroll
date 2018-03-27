module BenefitSponsors
  module BenefitPackages
    class SponsorContribution
      include Mongoid::Document
      include Mongoid::Timestamps

      embedded_in :sponsored_benefit, class_name: "BenefitSponsors::BenefitPackages::SponsoredBenefit"
   
    end
  end
end