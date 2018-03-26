module BenefitSponsors::CensusMembers
  class CensusEmployee < CensusMember

    has_many :census_survivors, class_name: "BenefitSponsors::CensusMembers::CensusSurvivor"
    embeds_many :census_dependents, as: :census_dependent, class_name: "BenefitSponsors::CensusMembers::CensusDependent"
    
  end
end
