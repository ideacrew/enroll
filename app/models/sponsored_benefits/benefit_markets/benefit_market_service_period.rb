module SponsoredBenefits
  module BenefitMarkets
    class BenefitMarketServicePeriod
      include Mongoid::Document
      include Mongoid::Timestamps

      # Time periods when sponsors may initially offer, and subsequently renew, benefits
      #   :monthly - may start first of any month of the year and renews each year in same month
      #   :annual  - may start only on benefit market's annual effective date month and renews each year in same month
      #   :annual_with_midyear_initial - may start mid-year and renew at subsequent annual effective date month
      APPLICATION_INTERVAL_KINDS = [:monthly, :annual, :annual_with_midyear_initial]

      embedded_in :benefit_market, class_name: "SponsoredBenefits::BenefitMarkets::BenefitMarket"

      attr_reader :service_area, :benefit_products

      # Frequency at which sponsors may submit an initial or renewal application
      # Example application interval kinds:
      #   DC Individual Market, Congress:
      #     :application_interval_kind => :annual
      #   MA GIC
      #     :application_interval_kind => :annual_with_midyear_initial
      #   DC/MA SHOP Market:
      #     :application_interval_kind => :monthly
      field :application_interval_kind,  type: Symbol

      # Effective date range during which associated benefits may be offered by sponsors
      # Example application periods:
      #   DC Individual Market Initial & Renewal, Congress:
      #     :application_period => Date.new(2018,1,1)..Date.new(2018,12,31)
      #   MA GIC
      #     :application_period => Date.new(2018,7,1)..Date.new(2018,6,30)
      #   DC/MA SHOP Market:
      #     :application_period => Date.new(2018,1,1)..Date.new(2018,12,31)
      field :application_period,          type: Range

      # Length of time new members must wait before they're eligible to enroll
      field :probation_period_kinds,      type: Array,  default: SponsoredBenefits::PROBATION_PERIOD_KINDS

      field :title,                       type: String, default: ""
      field :description,                 type: String, default: ""

      embeds_one :benefit_product_catalog,            class_name: "SponsoredBenefits::BenefitProducts::BenefitProductCatalog"
      embeds_one :sponsor_eligibility_policy,         class_name: "SponsoredBenefits::BenefitMarkets::SponsorEligibilityPolicy"
      embeds_one :benefit_product_eligibility_policy, class_name: "SponsoredBenefits::BenefitMarkets::BenefitProductEligibilityPolicy"

      validates_presence_of :application_interval_kind, :application_period, :probation_period_kinds

      validates :application_interval_kind,
        inclusion:    { in: APPLICATION_INTERVAL_KINDS, message: "%{value} is not a valid application interval kind" },
        allow_nil:    false

      # validates :probation_period_kinds,
      #   inclusion:    { in: SponsoredBenefits::PROBATION_PERIOD_KINDS, message: "%{value} is not a valid probation period kind" },
      #   allow_nil:    false


      def service_area
        return @service_area if defined?(@service_area)
        @service_area = SponsoredBenefits::Locations::ServiceArea.find_by_benefit_market_service_period(self)
      end

      def benefit_products
        return @benefit_products if defined?(@benefit_products)
        @benefit_products = SponsoredBenefits::BenefitProducts::BenefitProduct.find_by_benefit_market_service_period(self)
      end

    end
  end
end
