# 
# Example BenefitServicePeriod's Annual Effective Periods
#   DC & MA SHOP: Jan-Dec
#   DC IVL: Jan-Dec
#   MA IVL: July-June
#   GIC: July-June 

module SponsoredBenefits
  module BenefitMarkets
    class BenefitServicePeriod
      include Mongoid::Document
      include Mongoid::Timestamps

      # Frequency when new applicants may initially enroll and renew benefits
      #   :monthly - may start first of any month in the year and renews each year in same month
      #   :annual_only - may start only on annual effective date month and renews each year in same month
      #   :annual_with_monthly_initial - may start mid-year and renew at subsequent annual effective date month

      EFFECTIVE_PERIOD_KINDS = [:monthly, :annual_only, :annual_with_monthly_initial]

      embedded_in :benefit_market, class_name: "SponsoredBenefits::BenefitMarkets::BenefitMarket"

      field :effective_period,              type: Range
      field :effective_period_kind,         type: Symbol
      field :annual_effective_period_month, type: Integer,  default: 1  # January 
      field :description,                   type: String,   default: ""

      embeds_one  :sponsor_eligibility_policy, class_nmae: "SponsoredBenefits::BenefitProducts::SponorEligibilityPolicy"

      has_many :service_areas, class_name: "SponsoredBenefits::Locations::ServiceArea"
      has_and_belongs_to_many :benefit_products, class_name: "SponsoredBenefits::BenefitProducts::BenefitProduct"

      validates :effective_period_kind,
        inclusion: { in: EFFECTIVE_PERIOD_KINDS, message: "%{value} is not a valid initial effective date kind" }


      def benefit_product_folio
      end


      def open_enrollment_begin_on
        open_enrollment_period.begin
      end

      def open_enrollment_end_on
        open_enrollment_period.end
      end

      def issuer_profiles
        benefit_products.uniq { |bp| bp.issuer_profile } || []
      end

      def benefit_products_by_kind(benefit_product_kind)
        benefit_products.collect { |bp| bp if bp.benefit_product_kind == benefit_product_kind } || []
      end

    end
  end
end
