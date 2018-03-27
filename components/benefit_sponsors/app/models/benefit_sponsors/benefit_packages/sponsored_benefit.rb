module BenefitSponsors
  module BenefitPackages
    class SponsoredBenefit
      include Mongoid::Document
      include Mongoid::Timestamps

      embedded_in :benefit_package, class_name: "BenefitSponsors::BenefitPackages::BenefitPackage"

    end
  end
end
