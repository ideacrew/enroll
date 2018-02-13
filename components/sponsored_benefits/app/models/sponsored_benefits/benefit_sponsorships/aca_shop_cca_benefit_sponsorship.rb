module SponsoredBenefits
  module BenefitSponsorships
    class AcaShopCcaBenefitSponsorship < BenefitSponsorship

      # Move CCA-specific PlanYear code here. e.g. Employer Attestation, SIC codes, etc

      field :sic_code,     to: :benefit_sponsorable
      field :rating_area,  to: :benefit_sponsorable

      validates_inclusion_of :recorded_rating_area, :in => market_rating_areas, :allow_nil => true


    end
  end
end
