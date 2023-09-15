# frozen_string_literal: true

module Config
  # Helper module for Config::AcaHelper
  module AcaHelper
    def employer_attestation_is_enabled?
      Settings.aca.employer_attestation
    end

    def individual_market_is_enabled?
      @individual_market_is_enabled ||= Settings.aca.market_kinds.include?("individual")
    end

    def aca_broker_routing_information
      Settings.aca.broker_routing_information
    end

    def site_broker_claim_quoting_enabled?
      Settings.site.broker_claim_quoting_enabled
    end

    def allow_mid_month_voluntary_terms?
      Settings.aca.shop_market.mid_month_benefit_application_terminations.voluntary
    end

    def allow_mid_month_non_payment_terms?
      Settings.aca.shop_market.mid_month_benefit_application_terminations.non_payment
    end

    def show_termination_reasons?
      Settings.aca.shop_market.mid_month_benefit_application_terminations.show_termination_reasons
    end

    def plan_match_tool_is_enabled?
      Settings.aca.plan_match_tool
    end

    def aca_shop_market_census_employees_template_file
      @aca_shop_market_census_employees_template_file ||= Settings.aca.shop_market.census_employees_template_file
    end

    def ce_roster_bulk_upload_enabled?
      EnrollRegistry.feature?(:ce_roster_bulk_upload) && EnrollRegistry.feature_enabled?(:ce_roster_bulk_upload)
    end
  end
end
