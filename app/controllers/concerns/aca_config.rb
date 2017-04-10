module AcaConfig
  def aca_qle_period
    Settings.aca.qle.with_in_sixty_days
  end

  def aca_shop_market_cobra_enrollment_period_in_months
    Settings.aca.shop_market.cobra_enrollment_period.months
  end
end
