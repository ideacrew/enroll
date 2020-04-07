module Config::AcaModelConcern
  extend ActiveSupport::Concern

  included do
    delegate :aca_state_name, to: :class
    delegate :aca_state_abbreviation, to: :class
    delegate :aca_shop_market_cobra_enrollment_period_in_months, to: :class
    delegate :aca_shop_market_employer_family_contribution_percent_minimum, to: :class
    delegate :aca_shop_market_employer_contribution_percent_minimum, to: :class
    delegate :aca_shop_market_new_employee_paper_application_is_enabled?, to: :class
    delegate :aca_shop_market_transmit_scheduled_employers, to: :class
    delegate :aca_shop_market_transmit_employer_carrier_drop_events, to: :class
    delegate :aca_shop_market_employer_transmission_day_of_month, to: :class
    delegate :aca_shop_market_census_employees_template_file, to: :class
    delegate :individual_market_is_enabled?, to: :class
    delegate :fehb_market_is_enabled?, to: :class
    delegate :general_agency_enabled?, to: :class
    delegate :use_simple_employer_calculation_model?, to: :class
    delegate :market_rating_areas, to: :class
    delegate :multiple_market_rating_areas?, to: :class
    delegate :constrain_service_areas?, to: :class
    delegate :transmit_employers_immediately?, to: :class
    delegate :enforce_employer_attestation?, to: :class
    delegate :employee_participation_ratio_minimum, to: :class
    delegate :non_owner_participation_count_minimum, to: :class
    delegate :aca_shop_market_small_market_employee_count_maximum, to: :class
    delegate :standard_industrial_classification_enabled?, to: :class
    delegate :offer_sole_source?, to: :class
    delegate :carrier_filters_enabled?, to: :class
    delegate :enrollment_shopping_start_day_offset, to: :class
    delegate :sic_field_exists_for_employer?, to: :class
    delegate :employer_attestation_is_enabled?, to: :class
    delegate :plan_match_tool_is_enabled?, to: :class
    delegate :dental_market_enabled?, to: :class
    delegate :allow_mid_month_voluntary_terms?, to: :class
    delegate :show_termination_reasons?, to: :class
    delegate :allow_mid_month_non_payment_terms?, to: :class
    delegate :enabled_metal_levels, to: :class
    delegate :offerings_constrained_to_service_areas?, to: :class
  end

  class_methods do
    def aca_shop_market_cobra_enrollment_period_in_months
      @@aca_shop_market_cobra_enrollment_period_in_months ||= Settings.aca.shop_market.cobra_enrollment_period.months
    end

    def aca_shop_market_small_market_employee_count_maximum
      @@aca_shop_market_small_market_employee_count_maximum ||= Settings.aca.shop_market.small_market_employee_count_maximum
    end

    def aca_state_abbreviation
      @aca_state_abbreviation ||= Settings.aca.state_abbreviation
    end

    def aca_state_name
      @@aca_state_name ||= Settings.aca.state_name
    end

    def aca_shop_market_employer_family_contribution_percent_minimum
      @@aca_shop_market_employer_family_contribution_percent_minimum ||= Settings.aca.shop_market.employer_family_contribution_percent_minimum
    end

    def aca_shop_market_new_employee_paper_application_is_enabled?
      @@aca_shop_market_new_employee_paper_application ||= Settings.aca.shop_market.new_employee_paper_application
    end

    def aca_shop_market_employer_contribution_percent_minimum
      @@aca_shop_market_employer_contribution_percent_minimum ||= Settings.aca.shop_market.employer_contribution_percent_minimum
    end

    def aca_shop_market_transmit_scheduled_employers
      @@aca_shop_market_transmit_scheduled_employers ||= Settings.aca.shop_market.transmit_scheduled_employers
    end

    def aca_shop_market_transmit_employer_carrier_drop_events
      @@aca_shop_market_transmit_scheduled_employers ||= Settings.aca.shop_market.transmit_carrier_drop_events
    end

    def aca_shop_market_employer_transmission_day_of_month
      @@aca_shop_market_employer_transmission_day_of_month ||= Settings.aca.shop_market.employer_transmission_day_of_month
    end

    def aca_shop_market_census_employees_template_file
      @@aca_shop_market_census_employees_template_file ||= Settings.aca.shop_market.census_employees_template_file
    end

    def individual_market_is_enabled?
      @@individual_market_is_enabled ||= Settings.aca.market_kinds.include? "individual"
    end

    def fehb_market_is_enabled?
      @fehb_market_is_enabled ||= Settings.aca.market_kinds.include?("fehb")
    end

    def general_agency_enabled?
      @@genearl_agency_enabled ||= Settings.aca.general_agency_enabled
    end

    def broker_carrier_appointments_enabled?
      @@broker_carrier_appointments_enabled ||= Settings.aca.broker_carrier_appointments_enabled
    end

    def use_simple_employer_calculation_model?
      @@use_simple_employer_calculation_model ||= (Settings.aca.use_simple_employer_calculation_model.to_s.downcase == "true")
    end

    def market_rating_areas
      @@market_rating_areas ||= Settings.aca.rating_areas
    end

    def multiple_market_rating_areas?
      @@multiple_market_rating_areas ||= Settings.aca.rating_areas.many?
    end

    def constrain_service_areas?
      @@constrain_service_areas ||= (Settings.aca.offerings_constrained_to_service_areas.to_s.downcase == "true")
    end

    def transmit_employers_immediately?
      @@transmit_employers_immediately ||= (Settings.aca.transmit_employers_immediately.to_s.downcase == "true")
    end

    def enforce_employer_attestation?
      @@enforce_employer_attestation ||= (Settings.aca.enforce_employer_attestation.to_s.downcase == "true")
    end

    def employee_participation_ratio_minimum
      @@employee_participation_ratio_minimum ||= Settings.aca.shop_market.employee_participation_ratio_minimum.to_f
    end

    def non_owner_participation_count_minimum
      @@non_owner_participation_count_minimum ||= Settings.aca.shop_market.non_owner_participation_count_minimum.to_f
    end

    def standard_industrial_classification_enabled?
      @@standard_industrial_classification_enabled ||= Settings.aca.shop_market.standard_industrial_classification
    end

    def offer_sole_source?
      @@offer_sole_source ||= Settings.aca.plan_options_available.include?("sole_source")
    end

    def carrier_filters_enabled?
      @@carrier_filters_enabled ||= Settings.aca.shop_market.carrier_filters_enabled
    end

    def employer_attestation_is_enabled?
      @@employer_attestation ||= Settings.aca.employer_attestation
    end

    def plan_match_tool_is_enabled?
      @@plan_match_tool ||= Settings.aca.plan_match_tool
    end

    def dental_market_enabled?
      @dental_market_enabled ||= Settings.aca.dental_market_enabled
    end

    def allow_mid_month_voluntary_terms?
      @allow_mid_month_voluntary_terms ||= Settings.aca.shop_market.mid_month_benefit_application_terminations.voluntary
    end

    def show_termination_reasons?
      @show_termination_reasons ||= Settings.aca.shop_market.mid_month_benefit_application_terminations.show_termination_reasons
    end

    def allow_mid_month_non_payment_terms?
      @allow_mid_month_non_payment_terms ||= Settings.aca.shop_market.mid_month_benefit_application_terminations.non_payment
    end

    def enrollment_shopping_start_day_offset
      @@enrollment_shopping_start_day_offset ||= Settings.aca.shop_market.initial_application.earliest_start_prior_to_effective_on.day_of_month.days
    end

    def sic_field_exists_for_employer?
      @@sic_field_exists_for_employer ||= Settings.aca.employer_has_sic_field
    end

    def validate_county?
      @@validate_count ||= Settings.aca.validate_county
    end

    def enabled_metal_levels
      @@enabled_metal_levels = Settings.aca.enabled_metal_levels_for_single_carrier
    end

    def offerings_constrained_to_service_areas?
      @@offerings_constrained_to_service_areas ||= Settings.aca.offerings_constrained_to_service_areas
    end

    def offers_nationwide_plans?
      @offers_nationwide_plans ||= Settings.aca.nationwide_markets
    end
  end
end
