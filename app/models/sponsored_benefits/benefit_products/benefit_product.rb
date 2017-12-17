module SponsoredBenefits
  class BenefitProducts::BenefitProduct
    include Mongoid::Document
    include Mongoid::Timestamps

    belongs_to :issuer_profile
    belongs_to :benefit_market
    has_many :benefit_sponsorships

    field :sponsor_enrollment_period_id, type: String

    field :design_effective_period  # => jan 1 - dec 31, 2018
    field :product_rate_period      # => jan 1 - march 31, 2018


    # builders: sponsor (rating area, sic), effective_date

    ## Dates

    ## BenefitMarket's Product Design Effective Period (Annual) - AcaShopCca
    # DC & MA SHOP: Jan-Dec
    # DC IVL: Jan-Dec
    # MA IVL: July-June
    # GIC: July-June 

    ## Benefit Product rate period - BenefitProduct
    # DC & MA SHOP Health: Q1, Q2, Q3, Q4
    # DC Dental: annual
    # GIC Medicare: Jan-June, July-Dec
    # DC & MA IVL: annual



    # Effective dates during which sponsor may purchase this product at this price
    ## DC SHOP Health   - annual product changes & quarterly rate changes
    ## CCA SHOP Health  - annual product changes & quarterly rate changes
    ## DC IVL Health    - annual product & rate changes
    ## Medicare         - annual product & semiannual rate changes

    field :product_purchase_period, type: Range
    has_many :rate_tables



  end
end
