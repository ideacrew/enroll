module Config::AcaHelper

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
end