# BenefitMarket is a marketplace where BenefitSponsors choose benefit products to offer to their members.  Market behaviors and products 
# are governed by law, along with rules and policies of the market owner.  ACA Individual market and ACA SHOP market are two example market kinds.
# BenefitMarket owners publish and refresh benefit products on a periodic basis using BenefitCatalogs
module SponsoredBenefits
  module BenefitMarkets
    class BenefitMarket
      include Mongoid::Document
      include Mongoid::Timestamps

      PROBATION_PERIOD_KINDS  = [:first_of_month_before_15th, :date_of_hire, :first_of_month, :first_of_month_after_30_days, :first_of_month_after_60_days]

      attr_reader :configuration_setting, :contact_center_profile

      field :kind,        type: Symbol  # => :aca_shop
      field :title,       type: String, default: "" # => DC Health Link SHOP Market
      field :description, type: String, default: ""

      belongs_to  :site,                  class_name: "SponsoredBenefits::Site"
      has_many    :benefit_applications,  class_name: "SponsoredBenefits::BenefitApplications::BenefitApplication"
      has_many    :benefit_catalogs,      class_name: "SponsoredBenefits::BenefitCatalogs::BenefitCatalog"

      embeds_one :configuration_setting,  class_name: "SponsoredBenefits::BenefitMarkets::AcaIndividualConfiguration",
                                          autobuild: true
      # embeds_one :contact_center_setting, class_name: "SponsoredBenefits::BenefitMarkets::ContactCenterConfiguration",
      #                                     autobuild: true

      validates_presence_of :configuration_setting #, :contact_center_setting

      validates :kind,
        inclusion:  { in: SponsoredBenefits::BENEFIT_MARKET_KINDS, message: "%{value} is not a valid market kind" },
        allow_nil:  false

      index({ kind:  1 })

      # Mongoid initializes associations after setting attributes. It's necessary to autobuild the 
      # configuration file and subsequently change following initialization, if necessary
      after_initialize :initialize_configuration_setting

      def kind=(new_kind)
        return unless SponsoredBenefits::BENEFIT_MARKET_KINDS.include?(new_kind)
        @kind = new_kind
        write_attribute(:kind, new_kind)
        initialize_configuration_setting
      end

      # Catalogs with benefit products currently available for purchase
      def benefit_catalog_active_on(date = TimeKeeper.date_of_record)
        benefit_catalogs.detect { |catalog| catalog.application_period_cover?(date)}
      end

      # Calculate available effective dates periods using passed date
      def effective_periods_for(base_date = ::Timekeeper.date_of_record)
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

      def open_enrollment_minimum_begin_day_of_month(use_grace_period = false)
        if use_grace_period
          open_enrollment_end_on_day_of_month - open_enrollment_grace_period_minimum_length_days
        else
          open_enrollment_end_on_day_of_month - open_enrollment_minimum_length_days
        end
      end

      def open_enrollment_maximum_length
        # Settings.aca.shop_market.open_enrollment.maximum_length.months.months
        configuration.open_enrollment_months_max.months
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


      def reset_configuration_setting
        return unless kind.present?

        klass_name = configuration_class_name
        self.configuration_setting = klass_name.constantize.new
      end

      private

      def initialize_configuration_setting
        klass_name = configuration_class_name
        reset_configuration_setting if self.has_configuration_setting? && (klass_name != configuration_setting.class.to_s)

        configuration_setting
      end

      # Configuration setting model is automatically associated based on "kind" attribute value
      def configuration_class_name
        config_klass = "#{@kind.to_s}_configuration".camelcase
        namespace_for(self.class) + "::#{config_klass}"
      end

      # Isolate the namespace portion of the passed class
      def namespace_for(klass)
        klass_name = klass.to_s.split("::")
        klass_name.slice!(-1) || []
        klass_name.join("::")
      end

    end
  end
end
