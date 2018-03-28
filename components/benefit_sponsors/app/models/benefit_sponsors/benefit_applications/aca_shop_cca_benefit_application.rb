module BenefitSponsors
  module BenefitApplications
    class AcaShopCcaBenefitApplication < BenefitApplication
      include Concerns::AcaRatingAreaConfigConcern
      include Concerns::AcaShopBenefitApplicationConcern

      # Sponsor self-reported number of full-time employees
      field :fte_count, type: Integer, default: 0

      # Sponsor self-reported number of part-time employess
      field :pte_count, type: Integer, default: 0

      # Sponsor self-reported number of Medicare Second Payers
      field :msp_count, type: Integer, default: 0

      # Move CCA-specific PlanYear code here. e.g. Employer Attestation, SIC codes, etc

      # SIC code, frozen when the plan year is published,
      # otherwise comes from employer_profile
      field :recorded_sic_code,     type: String
      field :recorded_rating_area,  type: String

      validates_inclusion_of :recorded_rating_area, :in => market_rating_areas, :allow_nil => true
    end
  end
end
