module Config::SiteHelper
  def site_byline
    Settings.site.byline
  end

  def site_home_url
    Settings.site.home_url
  end

  def site_help_url
    Settings.site.help_url
  end

  def site_short_name
    Settings.site.short_name
  end
end
