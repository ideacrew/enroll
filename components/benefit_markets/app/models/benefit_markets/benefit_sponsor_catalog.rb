module BenefitMarkets
  class BenefitSponsorCatalog
    include Mongoid::Document
    include Mongoid::Timestamps

    field :effective_date,    type: Date 
    field :probation_periods, type: Array, default: []

    embeds_many :eligibilities
    embeds_many :product_packages

  end
end
