module Config::AcaHelper

  def employer_attestation_is_enabled?
    Settings.aca.employer_attestation
  end

  def individual_market_is_enabled?
    @individual_market_is_enabled ||= Settings.aca.market_kinds.include?("individual")
  end

end
