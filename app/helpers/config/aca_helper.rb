module Config::AcaHelper
  def aca_state_abbreviation
    Settings.aca.state_abbreviation
  end

  def aca_state_name
    Settings.aca.state_name
  end
  
  def individual_market_is_enabled?
    Settings.aca.market_kinds.include?("individual")
  end
end
