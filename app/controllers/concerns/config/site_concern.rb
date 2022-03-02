module Config::SiteConcern
  def site_short_name
    EnrollRegistry[:enroll_app].setting(:short_name).item
  end

  def site_uses_default_devise_path?
    Settings.site.use_default_devise_path
  end

  def site_create_routes
    EnrollRegistry[:enroll_app].setting(:create_routes).item
  end

  def site_sign_in_routes
    EnrollRegistry[:enroll_app].setting(:sign_in_routes).item
  end

  def site_redirect_on_timeout_route
    Settings.site.curam_enabled? ? SamlInformation.iam_login_url : new_user_session_path
  end

  def support_for_ie_browser?
    Settings.site.support_for_ie_browser
  end

  def is_broker_agency_enabled?
    EnrollRegistry.feature_enabled?(:brokers)
  end

  def is_general_agency_enabled?
    EnrollRegistry.feature_enabled?(:general_agency)
  end

  def is_shop_market_enabled?
    EnrollRegistry.feature_enabled?(:aca_shop_market)
  end

  def is_fehb_market_enabled?
    EnrollRegistry.feature_enabled?(:fehb_market)
  end

  def is_individual_market_enabled?
    EnrollRegistry.feature_enabled?(:aca_individual_market)
  end

  def is_shop_and_individual_market_enabled?
    EnrollRegistry.feature_enabled?(:aca_shop_market) && EnrollRegistry.feature_enabled?(:aca_individual_market)
  end

  def is_shop_or_fehb_market_enabled?
    EnrollRegistry.feature_enabled?(:aca_shop_market) || EnrollRegistry.feature_enabled?(:fehb_market)
  end
end
