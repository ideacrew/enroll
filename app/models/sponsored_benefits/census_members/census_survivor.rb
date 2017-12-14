module SponsoredBenefits
  class CensusMembers::CensusSurvivor  < CensusMembers::CensusMember
    
    embeds_many :census_dependents, as: :census_dependent, class_name: "SponsoredBenefits::CensusMembers::CensusDependent"

  end
end
