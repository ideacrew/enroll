module SponsoredBenefits
  class BenefitProducts::BenefitProduct
    include Mongoid::Document
    include Mongoid::Timestamps

    belongs_to :issuer_profile
    belongs_to :benefit_market
    has_many :benefit_sponsorships

    field :sponsor_enrollment_period_id, type: String

    # Effective dates during which sponsor may purchase this product at this price
    ## DC SHOP Health   - annual product changes & quarterly rate changes
    ## CCA SHOP Health  - annual product changes & quarterly rate changes
    ## DC IVL Health    - annual product & rate changes
    ## Medicare         - annual product & semiannual rate changes

    field :product_purchase_period, type: Range
    has_many :rate_tables



  end
end
