class SamlController < ApplicationController
  skip_before_action :verify_authenticity_token
  # def init
  #   request = OneLogin::RubySaml::Authrequest.new
  #   redirect_to(request.create(saml_settings))
  # end

  def login
    response          = OneLogin::RubySaml::Response.new(params[:SAMLResponse])
    response.settings = saml_settings

    if response.is_valid?
      email = response.attributes['mail']

      user_with_email = User.where(email: email).first

      if user_with_email.present?
        sign_in(:user, user_with_email)
        redirect_to user_with_email.last_portal_visited
      else
        new_password = Devise.friendly_token.first(20)
        new_user = User.new(email: email, password: new_password)
        new_user.save!
        sign_in(:user, new_user)
        redirect_to search_insured_consumer_role_index_path
      end
    else
      render file: 'public/403.html', status: 403
    end
  end

  private

  def saml_settings
    settings = OneLogin::RubySaml::Settings.new

    settings.assertion_consumer_service_url = "https://enroll-test.dchbx.org/saml/login"
    settings.issuer                         = "https://enroll-test.dchbx.org/saml"
    settings.idp_sso_target_url             = "https://DHSDCASOHSSVRQA201.dhs.dc.gov:4443/fed/idp/samlv20"
    settings.idp_cert_fingerprint           = "96:ED:14:CD:A1:2D:9D:AD:EC:47:1C:85:79:72:37:FB:91:65:13:B5"
    settings.idp_cert_fingerprint_algorithm = "http://www.w3.org/2000/09/xmldsig#sha1"
    settings.name_identifier_format         = "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"

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
