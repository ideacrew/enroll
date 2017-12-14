module SponsoredBenefits
  class CensusMembers::CensusSurvivor  < CensusMembers::CensusMember
    include Mongoid::Document

    embeds_many :census_dependents, class_name: "CensusMembers::CensusDependent"

  end
end
