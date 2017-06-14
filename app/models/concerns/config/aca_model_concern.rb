module Config::AcaModelConcern
  extend ActiveSupport::Concern

  included do
    delegate :aca_state_name, to: :class
    delegate :aca_state_abbreviation, to: :class
    delegate :aca_shop_market_cobra_enrollment_period_in_months, to: :class
    delegate :individual_market_is_enabled?, to: :class
    delegate :general_agency_enabled?, to: :class
    delegate :use_simple_employer_calculation_model?, to: :class
  end

  class_methods do
    def aca_shop_market_cobra_enrollment_period_in_months
      @@aca_shop_market_cobra_enrollment_period_in_months ||= Settings.aca.shop_market.cobra_enrollment_period.months
    end

    def aca_state_abbreviation
      @aca_state_abbreviation ||= Settings.aca.state_abbreviation
    end

    def aca_state_name
      @@aca_state_name ||= Settings.aca.state_name
    end

    def individual_market_is_enabled?
      @@individual_market_is_enabled ||= Settings.aca.market_kinds.include? "individual"
    end

    def general_agency_enabled?
      @@genearl_agency_enabled ||= Settings.aca.general_agency_enabled
    end

    def use_simple_employer_calculation_model?
      @@use_simple_employer_calculation_model ||= (Settings.aca.use_simple_employer_calculation_model.to_s.downcase == "true")
    end
  end
end
