module Config::SiteConcern
  def site_short_name
    Settings.site.short_name
  end

  def site_uses_default_devise_path?
    Settings.site.use_default_devise_path
  end
end
