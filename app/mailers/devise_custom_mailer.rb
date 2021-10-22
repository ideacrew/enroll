class DeviseCustomMailer < Devise::Mailer   
  helper :application
  include Devise::Controllers::UrlHelpers
  default template_path: 'devise/mailer'
  ### add_template_helper makes the view helper methods available in the Mailer templates. It does NOT make the methods available in the Mailer itself
  ### Thus we have to use Include in addition to add_template_helper
  add_template_helper Config::AcaHelper
  add_template_helper Config::SiteHelper
  add_template_helper Config::ContactCenterHelper
  add_template_helper ::L10nHelper
  include Config::AcaHelper
  include Config::SiteHelper
  include Config::ContactCenterHelper
  include ::L10nHelper
  layout EnrollRegistry[:custom_email_templates].settings(:email_template).item if EnrollRegistry.feature_enabled?(:custom_email_templates)


  if Rails.env.production?
    self.delivery_method = :soa_mailer
  end
end
