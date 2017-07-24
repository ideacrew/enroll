module Config::SiteHelper
  def site_byline
    Settings.site.byline
  end

  def site_domain_name
    Settings.site.domain_name
  end

  def site_website_name
    Settings.site.website_name
  end
  
  def site_website_link
    link_to site_website_name, site_website_name
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

  def site_business_resource_center_url
    Settings.site.business_resource_center_url
  end

  def site_nondiscrimination_notice_url
    Settings.site.nondiscrimination_notice_url
  end

  def site_faqs_url
    Settings.site.faqs_url
  end

  def site_short_name
    Settings.site.short_name
  end

  def site_registration_path(resource_name, params)
    Settings.site.registration_path.present? ? Settings.site.registration_path : new_registration_path(resource_name, :invitation_id => params[:invitation_id])
  end

  def site_long_name
    Settings.site.long_name
  end

  def site_registration_path(resource_name, params)
    Settings.site.registration_path.present? ? Settings.site.registration_path : new_registration_path(resource_name, :invitation_id => params[:invitation_id])
  end

  def site_broker_quoting_enabled?
    Settings.site.broker_quoting_enabled
  end

  def site_main_web_address
    Settings.site.main_web_address
  end

  def site_main_web_address_url
    Settings.site.main_web_address_url
  end

  def site_main_web_link
    link_to site_main_web_address, site_main_web_address
  end

  def site_make_their_premium_payments_online
    Settings.site.make_their_premium_payments_online
  end

  def site_uses_default_devise_path?
    Settings.site.use_default_devise_path
  end

  def find_your_doctor_url
    Settings.site.shop_find_your_doctor_url
  end

  def site_main_web_address_text
    Settings.site.main_web_address_text
  end

  def site_document_verification_checklist_url
    Settings.site.document_verification_checklist_url
  end
end
