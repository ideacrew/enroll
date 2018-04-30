module BenefitMarkets
  class BenefitSponsorCatalog
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :benefit_application

    field :effective_date,    type: Date 
    field :probation_period_options, type: Array, default: []
    field :service_area_id

    embeds_one  :sponsor_eligibility_policy,  
                class_name: "BenefitMarkets::SponsorEligibilityPolicy"
    embeds_one  :member_eligibility_policy,
                class_name: "BenefitMarkets::MemberEligibilityPolicy"

    embeds_many :policies,
                class_name: "BenefitMarket::Policies::Policy"
    embeds_many :product_packages,
                class_name: "Products::ProductPackage"
  end
end
