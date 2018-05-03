module BenefitSponsors::CensusMembers
  class CensusEmployee < CensusMember

    belongs_to  :benefit_sponsorship,
            class_name: "BenefitSponsors::BenefitSponsorships::BenefitSponsorship"


    has_many :census_survivors, class_name: "BenefitSponsors::CensusMembers::CensusSurvivor"
    embeds_many :census_dependents, as: :census_dependent, class_name: "BenefitSponsors::CensusMembers::CensusDependent"
    
    class << self
    end
  end
end
