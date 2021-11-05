class SamlController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :redirect_if_medicaid_tax_credits_link_is_disabled, only: [:navigate_to_assistance]
  include Acapi::Notifiers
  # def init
  #   request = OneLogin::RubySaml::Authrequest.new
  #   redirect_to(request.create(saml_settings))
  # end

  def login
    response          = OneLogin::RubySaml::Response.new(params[:SAMLResponse], :allowed_clock_drift => 5.seconds)
    response.settings = saml_settings

    relay_state = params['RelayState'] || response.attributes['relay_state']
    sign_out current_user if current_user.present?

    if response.is_valid? && response.name_id.present?
      oim_user = if EnrollRegistry[:identity_management_config].settings(:identity_manager).item == :keycloak
                   User.where(account_id: response.attributes['id']).first
                 else
                   username = response.name_id.downcase
                   User.where(oim_id: /^#{Regexp.escape(username)}$/i).first
                 end

      if oim_user.present?
        oim_user.idp_verified = true
        oim_user.oim_id = response.name_id

        unless oim_user.valid?
          log("ERROR: #{oim_user.errors.messages}", {:severity => "error"})
          return redirect_to URI.parse(SamlInformation.iam_login_url).to_s, flash: {error: "Invalid User Details."}
        end

        oim_user.save!
        ::IdpAccountManager.update_navigation_flag(
          oim_user.oim_id,
          response.attributes['mail'],
          ::IdpAccountManager::ENROLL_NAVIGATION_FLAG
        )
        sign_in(:user, oim_user)
        if !relay_state.blank?
          oim_user.update_attributes!(last_portal_visited: relay_state)
          redirect_to URI.parse(relay_state).to_s, flash: {notice: "Signed in Successfully."}
        elsif !oim_user.last_portal_visited.blank?
          redirect_to URI.parse(oim_user.last_portal_visited).to_s, flash: {notice: "Signed in Successfully."}
        else
          oim_user.update_attributes!(last_portal_visited: search_insured_consumer_role_index_path)
          redirect_to search_insured_consumer_role_index_path, flash: {notice: "Signed in Successfully."}
        end
      else
        new_password = User.generate_valid_password
        new_email = response.attributes['mail'].present? ? response.attributes['mail'] : ""

        headless = User.where(email: /^#{Regexp.escape(new_email)}$/i).first
        headless.destroy if headless.present? && !headless.person.present?
        new_user = User.new(email: new_email, password: new_password, idp_verified: true, oim_id: response.name_id)

        unless new_user.valid?
          log("ERROR: #{new_user.errors.messages}", {:severity => "error"})
          return redirect_to URI.parse(SamlInformation.iam_login_url).to_s, flash: {error: "Invalid User Details."}
        end

        new_user.save!
        ::IdpAccountManager.update_navigation_flag(
          response.name_id,
          response.attributes['mail'],
          ::IdpAccountManager::ENROLL_NAVIGATION_FLAG
        )
        sign_in(:user, new_user)
        if relay_state.blank?
          new_user.update_attributes!(last_portal_visited: search_insured_consumer_role_index_path)
          redirect_to search_insured_consumer_role_index_path, flash: {notice: "Signed in Successfully."}
        else
          new_user.update_attributes!(last_portal_visited: relay_state)
          redirect_to URI.parse(relay_state).to_s, flash: {notice: "Signed in Successfully."}
        end
      end
    elsif !response.name_id.present?
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
      redirect_to URI.parse(SamlInformation.curam_landing_page_url).to_s
    else
      redirect_to URI.parse(SamlInformation.iam_login_url).to_s
    end

  end

  def logout
    redirect_to URI.parse(SamlInformation.saml_logout_url).to_s
  end

  def redirection_test
    response = OneLogin::RubySaml::Response.new(params[:SAMLResponse])
    render json: {"SAMLresponse": response.response}
  end

  private

  def redirect_if_medicaid_tax_credits_link_is_disabled
    redirect_to(main_app.root_path, notice: l10n("medicaid_and_tax_credits_link_is_disabled")) unless EnrollRegistry.feature_enabled?(:medicaid_tax_credits_link)
  end

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
