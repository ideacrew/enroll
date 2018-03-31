module BenefitSponsors
  module SponsoredBenefits
    class ContributionLevel
      include Mongoid::Document
      include Mongoid::Timestamps


      embedded_in :sponsor_contribution,
                  class_name: "BenefitSponsors::SponsoredBenefits::SponsorContribution"


      field :is_offered, type: Boolean
      field :kind, type: Symbol
      field :contribution_pct, type: Integer
      field :contribution_min_pct, type: Integer
      # field :contribution_amt, type: Money
      # field :contribution_min_amt, type: Money
      # field :contribution_max_amt, type: Money
      
    end
  end
end
