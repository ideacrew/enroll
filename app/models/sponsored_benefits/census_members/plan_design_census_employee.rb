module SponsoredBenefits
  class CensusMembers::PlanDesignCensusEmployee < CensusMembers::CensusMember

    has_many :census_survivors, class_name: "CensusMembers::CensusSurvivor"
    embeds_many :census_dependents, class_name: "CensusMembers::CensusDependent"

  end
end
