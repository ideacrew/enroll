module SponsoredBenefits
  module BenefitMarkets
    class BenefitMarket
      include Mongoid::Document
      include Mongoid::Timestamps

      SERVICE_MARKET_KINDS    = [:aca_shop, :aca_individual]
      PROBATION_PERIOD_KINDS  = [:first_of_month_before_15th, :date_of_hire, :first_of_month, :first_of_month_after_30_days, :first_of_month_after_60_days]

      field :title,               type: String, default: "" # => DC Health Link SHOP Market
      field :service_market_kind, type: Symbol  # => :aca_shop
      field :site_id,             type: Symbol  # For example, :dc, :cca

      has_many    :benefit_applications, class_name: "SponsoredBenefits::BenefitApplications::BenefitApplication"
      embeds_many :benefit_market_service_periods, class_name: "SponsoredBenefits::BenefitMarkets::BenefitMarketServicePeriod"

      validates_presence_of :site_id, :effective_period
      
      validates :service_market_kind,
        inclusion: { in: SERVICE_MARKET_KINDS, message: "%{value} is not a valid service market" }

      index({ "benefit_market_service_period._id" => 1 })
      index({ "benefit_market_service_period.effective_period.begin" => 1, 
              "benefit_market_service_period.effective_period.end" => 1 },
            { name: "benefit_market_service_period_effective_period" })

      # Return list of unique product kinds 
      scope :benefit_product_kinds,                   ->{}
      scope :benefit_product_kinds_by_effective_date, ->(effective_date = Timekeeper.DateOfRecord) {}
      scope :service_areas,   ->{}
      scope :benefit_applications,   ->{  }


      def benefit_enrollment_scopes_by_date(date)
        effective_dates = effective_dates_for(date)
        effective_dates.reduce([]) { |scopes, effective_date| scopes << build_benefit_application_scope(effective_date) }
      end

      # Calculate available effective dates periods using passed date
      def effective_date_periods_for(base_date = ::Timekeeper.date_of_record)
        start_on = if TimeKeeper.date_of_record.day > open_enrollment_minimum_begin_day_of_month
          TimeKeeper.date_of_record.beginning_of_month + open_enrollment_maximum_length
        else
          TimeKeeper.date_of_record.prev_month.beginning_of_month + open_enrollment_maximum_length
        end

        end_on = TimeKeeper.date_of_record - Settings.aca.shop_market.initial_application.earliest_start_prior_to_effective_on.months.months
        (start_on..end_on).select {|t| t == t.beginning_of_month}
      end

      def calculate_start_on_options
        calculate_start_on_dates.map {|date| [date.strftime("%B %Y"), date.to_s(:db) ]}
      end

      def benefit_market_service_period_by_effective_date(effective_date)
        benefit_market_service_periods.select { |service_period| service_period.effective_period.contains?(effective_date) }
      end


      def build_benefit_application_scope(effective_date)
        SponsoredBenefits::BenefitMarkets::BenefitApplicationScope.new(effective_date, self)
      end

      def open_enrollment_minimum_begin_day_of_month(use_grace_period = false)
        if use_grace_period
          open_enrollment_end_on_day_of_month - open_enrollment_grace_period_minimum_length_days
        else
          open_enrollment_end_on_day_of_month - open_enrollment_minimum_length_days
        end
      end

      def issuer_profiles_by_effective_date(effective_date)
        bp = benefit_market_service_period_by_effective_date(effective_date)
        bp.issuer_profiles if bp.present?
      end

      def benefit_products_by_effective_date(effective_date)
        bp = benefit_market_service_period_by_effective_date(effective_date)
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


      private 

      def open_enrollment_maximum_length
        Settings.aca.shop_market.open_enrollment.maximum_length.months.months
      end

      def open_enrollment_end_on_day_of_month
        Settings.aca.shop_market.open_enrollment.monthly_end_on
      end

      def open_enrollment_minimum_length_days
        Settings.aca.shop_market.open_enrollment.minimum_length.adv_days
      end

      def open_enrollment_grace_period_minimum_length_days
        Settings.aca.shop_market.open_enrollment.minimum_length.days
      end


    end
  end
end
