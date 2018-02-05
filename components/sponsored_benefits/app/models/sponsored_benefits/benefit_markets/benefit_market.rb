module SponsoredBenefits
  module BenefitMarkets
    class BenefitMarket
      include Mongoid::Document
      include Mongoid::Timestamps

      SERVICE_MARKET_KINDS  = [:aca_shop, :aca_individual]

      field :title,               type: String, default: "" # => DC Health Link SHOP Market
      field :service_market_kind, type: Symbol  # => :aca_shop
      field :site_id,             type: Symbol  # For example, :dc, :cca

      # field :annual_service_period_begin_month_of_year, type: Integer

      embeds_many :benefit_service_periods, class_name: "SponsoredBenefits::BenefitMarkets::BenefitServicePeriod"

      validates_presence_of :site_id, :effective_period
      
      validates :service_market_kind,
        inclusion: { in: SERVICE_MARKET_KINDS, message: "%{value} is not a valid service market" }

      index("benefit_service_period._id" => 1)

      # Return list of unique product kinds 
      scope :benefit_product_kinds,                   ->{}
      scope :benefit_product_kinds_by_effective_date, ->(effective_date = Timekeeper.DateOfRecord) {}
      scope :service_areas,   ->{}


      def next_initial_enrollment_effective_date
      end

      def next_renewal_enrollment_effective_date
      end

      def benefit_service_periods_by_effective_date(effective_date)
        benefit_service_periods.detect { |service_period| service_period.effective_period.contains?(effective_date) } || []
      end

      def issuer_profiles_by_effective_date(effective_date)
        bp = benefit_service_period_by_effective_date(effective_date)
        bp.issuer_profiles if bp.present?
      end

      def benefit_products_by_effective_date(effective_date)
        bp = benefit_service_period_by_effective_date(effective_date)
        bp.benefit_products if bp.present?
      end

      def benefit_products_by_effective_date_and_kind(effective_date, benefit_product_kind)
        bp = benefit_products_by_effective_date(effective_date)
        bp.benefit_products_by_kind if bp.present?
      end


    ## GIC
    # Open Enrollment
    #   Annual
    # Life Insurance
    #   
    # Medicare
    #   Special Enrollment - monthly
    #   Age 65
    #   Rate updates - every 6 months


    end
  end
end
