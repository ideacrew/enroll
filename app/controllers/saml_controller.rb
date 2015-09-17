class SamlController < ApplicationController
  skip_before_action :verify_authenticity_token
  include Acapi::Notifiers
  # def init
  #   request = OneLogin::RubySaml::Authrequest.new
  #   redirect_to(request.create(saml_settings))
  # end

  def login
    response          = OneLogin::RubySaml::Response.new(params[:SAMLResponse])
    response.settings = saml_settings

    if response.is_valid?
      email = response.attributes['mail'].downcase

      user_with_email = User.where(email: email).first

      if user_with_email.present?
        # if user.person.primary_family == "curam_landing"
        #   log("ERROR: no verified family recieved", {:severity => "error"})
        #   render file: 'public/403.html', status: 403
        # end
        user_with_email.idp_verified = true
        user_with_email.save!
        sign_in(:user, user_with_email)
        redirect_to user_with_email.last_portal_visited
      else
        new_password = User.generate_valid_password
        new_user = User.new(email: email, password: new_password, idp_verified: true)
        new_user.save!
        sign_in(:user, new_user)
        redirect_to search_insured_consumer_role_index_path
      end
    else
      log("ERROR: SAMLResponse assertion errors #{response.errors}", {:severity => "error"})
      render file: 'public/403.html', status: 403
    end
  end

  private

  def saml_settings
    settings = OneLogin::RubySaml::Settings.new

    settings.assertion_consumer_service_url = SamlInformation.assertion_consumer_service_url
    settings.issuer                         = SamlInformation.issuer
    settings.idp_sso_target_url             = SamlInformation.idp_sso_target_url
    settings.idp_cert_fingerprint           = SamlInformation.idp_cert_fingerprint
    settings.idp_cert_fingerprint_algorithm = SamlInformation.idp_cert_fingerprint_algorithm
    settings.name_identifier_format         = SamlInformation.name_identifier_format
    ## Optional for most SAML IdPs
    # settings.authn_context = "urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport"

    ## Optional. Describe according to IdP specification (if supported) which attributes the SP desires to receive in SAMLResponse.
    # settings.attributes_index = 5
    ## Optional. Describe an attribute consuming service for support of additional attributes.
    # settings.attribute_consuming_service.configure do
    #   service_name "Service"
    #   service_index 5
    #   add_attribute :name => "Name", :name_format => "Name Format", :friendly_name => "Friendly Name"
    # end

    settings
  end
end
