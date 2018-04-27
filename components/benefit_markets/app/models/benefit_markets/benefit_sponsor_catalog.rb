module BenefitMarkets
  class BenefitSponsorCatalog
    include Mongoid::Document
    include Mongoid::Timestamps

    field :effective_date,    type: Date 
    field :probation_period_options, type: Array, default: []

    embeds_many :policies,
                class_name: "BenefitMarket::Policies::Policy"
    embeds_many :product_packages,
                class_name: "Products::ProductPackage"

  end
end
