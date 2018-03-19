module SponsoredBenefits
  class RatingModels::MemberRelationshipMap
    include Mongoid::Document

    embedded_in :member_relationship,
                class_name: "SponsoredBenefits::RatingModels:MemberRelationship"


    field :rating_tier,   type: Symbol
    


  end
end
