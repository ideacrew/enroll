module Config::SiteHelper
  def site_byline
    Settings.site.byline
  end

  def site_domain_name
    Settings.site.domain_name
  end

  def site_find_expert_link
    link_to site_find_expert_url, site_find_expert_url
  end

  def site_find_expert_url
    site_home_url + "/find-expert"
  end

  def site_home_url
    Settings.site.home_url
  end

  def site_home_link
    link_to site_home_url, site_home_url
  end

  def site_help_url
    Settings.site.help_url
  end

  def site_short_name
    Settings.site.short_name
  end

  def site_broker_quoting_enabled?
    Settings.site.broker_quoting_enabled
  end
end
