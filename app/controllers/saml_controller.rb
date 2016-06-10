class SamlController < ApplicationController
  skip_before_action :verify_authenticity_token
  include Acapi::Notifiers
  # def init
  #   request = OneLogin::RubySaml::Authrequest.new
  #   redirect_to(request.create(saml_settings))
  # end

  def login
    relay_state = params["RelayState"]
    response          = OneLogin::RubySaml::Response.new(params[:SAMLResponse], :allowed_clock_drift => 5.seconds)
    response.settings = saml_settings

    sign_out current_user if current_user.present?

    if response.is_valid? && response.attributes['mail'].present?
      email = response.attributes['mail'].downcase

      user_with_email = User.where(email: email).first

      if user_with_email.present?
        user_with_email.idp_verified = true
        user_with_email.oim_id = response.name_id
        user_with_email.save!
        ::IdpAccountManager.update_navigation_flag(
          user_with_email.oim_id,
          email,
          ::IdpAccountManager::ENROLL_NAVIGATION_FLAG
        )
        sign_in(:user, user_with_email)
        if !relay_state.blank?
          user_with_email.update_attributes!(last_portal_visited: relay_state)
          redirect_to relay_state, flash: {notice: "Signed in Successfully."}
        elsif !user_with_email.last_portal_visited.blank?
          redirect_to user_with_email.last_portal_visited, flash: {notice: "Signed in Successfully."}
        else
          user_with_email.update_attributes!(last_portal_visited: search_insured_consumer_role_index_path)
          redirect_to search_insured_consumer_role_index_path, flash: {notice: "Signed in Successfully."}
        end
      else
        new_password = User.generate_valid_password
        new_user = User.new(email: email, password: new_password, idp_verified: true, oim_id: response.name_id)
        new_user.save!
        ::IdpAccountManager.update_navigation_flag(
          response.name_id,
          email,
          ::IdpAccountManager::ENROLL_NAVIGATION_FLAG
        )
        sign_in(:user, new_user)
        if relay_state.blank?
          new_user.update_attributes!(last_portal_visited: search_insured_consumer_role_index_path)
          redirect_to search_insured_consumer_role_index_path, flash: {notice: "Signed in Successfully."}
        else
          new_user.update_attributes!(last_portal_visited: relay_state)
          redirect_to relay_state, flash: {notice: "Signed in Successfully."}
        end
      end
    elsif !response.attributes['mail'].present?
      log("ERROR: SAMLResponse has missing required mail attribute", {:severity => "critical"})
      render file: 'public/403.html', status: 403
    else
      log("ERROR: SAMLResponse assertion errors #{response.errors}", {:severity => "error"})
      render file: 'public/403.html', status: 403
    end
  end

  # This action is invoked only when going to curam from the account page.
  # Going to curam during the initial flow is triggered differently.
  # What we do here is set the navigation flag and send to the right location.
  def navigate_to_assistance

    if current_user.present?

      ::IdpAccountManager.update_navigation_flag(
        current_user.oim_id,
        current_user.email,
        ::IdpAccountManager::CURAM_NAVIGATION_FLAG
      )
      # redirect_to destroy_user_session_path
      redirect_to SamlInformation.curam_landing_page_url
    else
      redirect_to SamlInformation.iam_login_url
    end

  end

  def logout
    redirect_to SamlInformation.saml_logout_url
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
