module SponsoredBenefits
  module BenefitMarkets
    class AcaIndividualConfiguration
      include Mongoid::Document
      include Mongoid::Timestamps

      embedded_in :benefit_market, class_name: "SponsoredBenefits::BenefitMarkets::BenefitMarket"

    end
  end
end
