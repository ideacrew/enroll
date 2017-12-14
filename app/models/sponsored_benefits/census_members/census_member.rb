module SponsoredBenefits
  class CensusMembers::CensusMember

    include Mongoid::Document
    include Mongoid::Timestamps
    
    store_in collection: 'census_members'


  end
end
