class WelcomeController < ApplicationController
  skip_before_filter :require_login

  def index
    redirect_to SamlInformation.saml_logout_url if Rails.env == "production"
  end

  def form_template
  	# created for generic form template access at '/templates/form-template'
  end
end
