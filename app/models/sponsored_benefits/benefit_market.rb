module SponsoredBenefits
  class BenefitMarket
    include Mongoid::Document
    include Mongoid::Timestamps

    has_many :benefit_products, class_name: "SponsoredBenefits::BenefitProducts::BenefitProduct"


  end
end
