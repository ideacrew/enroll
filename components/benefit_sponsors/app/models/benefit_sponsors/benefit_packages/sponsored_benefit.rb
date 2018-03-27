module BenefitSponsors
  module BenefitPackages
    class SponsoredBenefit
      include Mongoid::Document
      include Mongoid::Timestamps

      embedded_in :benefit_package, class_name: "BenefitSponsors::BenefitPackages::BenefitPackage"

      field :product_list, type: Array
      field :plan_option_kind, type: String
      field :rating_model_kind, type: Symbol

      field :reference_plan_id, type: BSON::ObjectId
      field :lowest_cost_plan_id, type: BSON::ObjectId
      field :highest_cost_plan_id, type: BSON::ObjectId
 
      embeds_one :sponsor_contribution, class_name: "BenefitSponsors::BenefitPackages::SponsorContribution"
    end
  end
end