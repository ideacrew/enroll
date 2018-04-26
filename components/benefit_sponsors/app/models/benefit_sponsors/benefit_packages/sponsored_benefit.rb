module BenefitSponsors
  class BenefitPackages::SponsoredBenefit
    include Mongoid::Document
    include Mongoid::Timestamps


    field :probation_period_kind, type: Symbol

    embeds_one :product_package


  end
end
