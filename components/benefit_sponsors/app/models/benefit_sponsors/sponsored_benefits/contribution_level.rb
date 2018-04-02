module BenefitSponsors
  module SponsoredBenefits
    class ContributionLevel
      include Mongoid::Document
      include Mongoid::Timestamps


      embedded_in :sponsor_contribution,
                  class_name: "BenefitSponsors::SponsoredBenefits::SponsorContribution"


      field :contribution_unit_id, type: BSON::ObjectId
      field :is_offered, type: Boolean
      
    end
  end
end
