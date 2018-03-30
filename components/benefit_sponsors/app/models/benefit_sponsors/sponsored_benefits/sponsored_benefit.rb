module BenefitSponsors
  module SponsoredBenefits
    class SponsoredBenefit
      include Mongoid::Document
      include Mongoid::Timestamps

      field :hbx_id,      type: String
      field :kind,        type: Symbol
      field :title,       type: String
      field :description, type: String

      embeds_many :benefit_products,      class_name: "::BenefitMarkets::Products::Product"
      embeds_one  :sponsor_contribution,  class_name: "::BenefitSponsors::SponsoredBenefits::SponsorConstribution"
      embeds_many :eligibility_policies,  class_name: "::BenefitMarkets::Products::EligibilityPolicies::EligibilityPolicy"

    end
  end
end
