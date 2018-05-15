module Config::SiteConcern
  def site_short_name
    Settings.site.short_name
  end
end
