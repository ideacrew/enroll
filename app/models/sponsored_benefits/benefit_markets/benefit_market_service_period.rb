# 
# Example BenefitServicePeriod's Annual Effective Periods
#   DC & MA SHOP: Jan-Dec
#   DC IVL: Jan-Dec
#   MA IVL: July-June
#   GIC: July-June module SponsoredBenefits
module BenefitMarkets
  class BenefitMarketServicePeriod
    include Mongoid::Document
    include Mongoid::Timestamps

    # Time periods when sponsors may initially offer, and subsequently renew, benefits
    #   :monthly - may start first of any month of the year and renews each year in same month
    #   :annual  - may start only on benefit market's annual effective date month and renews each year in same month
    #   :annual_with_midyear_initial - may start mid-year and renew at subsequent annual effective date month
    APPLICATION_FREQUENCY_KINDS = [:monthly, :annual, :annual_with_midyear_initial]

    embedded_in :benefit_market, class_name: "SponsoredBenefits::BenefitMarkets::BenefitMarket"

    attr_reader :service_areas, :benefit_products

    field :application_period,          type: Range
    field :application_frequency_kind,  type: Symbol
    field :probation_period_kinds,      type: Array,  default: SponsoredBenefits::BenefitMarkets::BenefitMarket::PROBATION_PERIOD_KINDS
    field :description,                 type: String, default: ""

    embeds_one :sponsor_eligibility_policy,         class_name: "SponsoredBenefits::BenefitMarkets::SponsorEligibilityPolicy"
    embeds_one :benefit_product_eligibility_policy, class_name: "SponsoredBenefits::BenefitMarkets::BenefitProductEligibilityPolicy"

    validates_presence_of :application_frequency_kind, :application_period,
                          :sponsor_eligibility_policy, :benefit_product_eligibility_policy, :probation_period_kinds

    validates :application_frequency_kind,
      inclusion:    { in: APPLICATION_FREQUENCY_KINDS, message: "%{value} is not a valid effective period kind" },
      allow_nil:    false


    def service_areas
      return @service_areas if defined?(@service_areas)
      @service_areas = SponsoredBenefits::Locations::ServiceArea.find_by_benefit_market_service_period(self)
    end

    def benefit_products
      return @benefit_products if defined?(@benefit_products)
      @benefit_products = SponsoredBenefits::BenefitProducts::BenefitProduct.find_by_benefit_market_service_period(self)
    end


  end
end
