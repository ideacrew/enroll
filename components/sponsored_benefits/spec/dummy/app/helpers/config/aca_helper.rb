module Config::AcaHelper
  def use_simple_employer_calculation_model?
    @use_simple_employer_calculation_model ||= (Settings.aca.use_simple_employer_calculation_model.to_s.downcase == "true")
  end

  def multiple_market_rating_areas?
    @multiple_market_rating_areas ||= Settings.aca.rating_areas.many?
  end
end
