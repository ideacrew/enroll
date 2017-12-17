module SponsoredBenefits
  class BenefitMarket
    include Mongoid::Document
    include Mongoid::Timestamps

    has_many :benefit_products, class_name: "SponsoredBenefits::BenefitProducts::BenefitProduct"

    # The date range in benefit products
    field :service_period,  type: Range


  end
end
