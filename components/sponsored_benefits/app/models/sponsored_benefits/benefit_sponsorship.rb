module SponsoredBenefits
  class BenefitSponsorship
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :sponsorable, polymorphic: true

    embeds_one  :geographic_rating_area, class_name: "SponsoredBenefits::Locations::GeographicRatingArea"

    has_many    :benefit_markets, class_name: "SponsoredBenefits::BenefitMarket" # (temporal: past, current and renewing)
    has_many    :offered_benefit_products, class_name: "SponsoredBenefits::BenefitProducts::BenefitProduct"
    has_many    :benefit_applications, cascade_callbacks: true, validate: true
    embeds_many :broker_agency_accounts, cascade_callbacks: true, validate: true




  end
end
