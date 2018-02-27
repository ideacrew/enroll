module SponsoredBenefits
  module BenefitMarkets
    class BenefitMarket
      include Mongoid::Document
      include Mongoid::Timestamps

      PROBATION_PERIOD_KINDS  = [:first_of_month_before_15th, :date_of_hire, :first_of_month, :first_of_month_after_30_days, :first_of_month_after_60_days]

      field :kind,        type: Symbol  # => :aca_shop
      field :title,       type: String, default: "" # => DC Health Link SHOP Market
      field :description, type: String, default: ""

      embeds_one :benefit_market_configuration
      embeds_one :contact_center_profile, class_name: "SponsoredBenefits::Organizations::ContactCenter"

      embeds_many :benefit_catalogs,      class_name: "SponsoredBenefits::BenefitCatalogs::BenefitCatalog",
        cascade_callbacks: true,
        validate: true

      belongs_to  :site,                  class_name: "SponsoredBenefits::Site"
      has_many    :benefit_applications,  class_name: "SponsoredBenefits::BenefitApplications::BenefitApplication"

      validates :kind,
        inclusion: { in: SponsoredBenefits::BENEFIT_MARKET_KINDS, message: "%{value} is not a valid market kind" },
        allow_nil:    false

      index({ "kind"  => 1 })
      index({ "benefit_catalogs._id" => 1 })
      index({ "benefit_catalogs.application_period.min" => 1,
              "benefit_catalogs.application_period.max" => 1 },
            { name: "benefit_catalogs_application_period" })

      scope :contains_date,   ->(date){ where(:"benefit_catalogs.application_period.min".gte => date,
                                              :"benefit_catalogs.application_period.max".lte => date)
                                            }

      def benefit_market_service_period_for(effective_date)
        SponsoredBenefits::BenefitMarkets::BenefitMarketCatalog.new(effective_date, self)
      end

      def benefit_market_catalog_for(effective_date)
        SponsoredBenefits::BenefitMarkets::BenefitMarketCatalog.new(effective_date, self)
      end

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
        benefit_catalogs.select { |service_period| service_period.effective_period.contains?(effective_date) }
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

      def renew_service_period
        @effective_period  = effective_date..(effective_date + 1.year - 1.day)
      end

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
