class DeviseCustomMailer < Devise::Mailer   
  helper :application
  include Devise::Controllers::UrlHelpers
  default template_path: 'devise/mailer'
  ### helper makes the view helper methods available in the Mailer templates. It does NOT make the methods available in the Mailer itself
  ### Thus we have to use Include in addition to helper
  helper Config::AcaHelper
  helper Config::SiteHelper
  helper Config::ContactCenterHelper
  helper ::L10nHelper
  include Config::AcaHelper
  include Config::SiteHelper
  include Config::ContactCenterHelper
  include ::L10nHelper
  layout EnrollRegistry[:custom_email_templates].settings(:email_template).item if EnrollRegistry.feature_enabled?(:custom_email_templates)


  if Rails.env.production?
    self.delivery_method = :soa_mailer
  end
end
