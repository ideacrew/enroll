module AcaTestHelper
  def aca_state_abbreviation
    @aca_state_abbreviation ||= Settings.aca.state_abbreviation
  end

  def self.aca_state_abbreviation
    @aca_state_abbreviation ||= Settings.aca.state_abbreviation
  end

  def individual_market_is_enabled?
    @individual_market_is_enabled ||= Settings.aca.market_kinds.include?("individual")
  end
end
