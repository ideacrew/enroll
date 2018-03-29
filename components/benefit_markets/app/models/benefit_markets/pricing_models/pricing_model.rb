module BenefitMarkets
  module PricingModels
    class PricingModel
      include Mongoid::Document
      include Mongoid::Timestamps

      field :name, type: String

      embeds_many :member_relationships, class_name: "::BenefitMarkets::PricingModels::MemberRelationship"
      embeds_many :pricing_units, class_name: "::BenefitMarkets::PricingModels::PricingUnit"
    end
  end
end
