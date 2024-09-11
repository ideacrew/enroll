class SamlController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :redirect_if_medicaid_tax_credits_link_is_disabled, only: [:navigate_to_assistance]
  include Acapi::Notifiers
  # def init
  #   request = OneLogin::RubySaml::Authrequest.new
  #   redirect_to(request.create(saml_settings))
  # end

  def account_expired
    flash[:error] = l10n('devise.failure.expired')
  end

  def login
    result = Operations::Authentication::LoginSamlUser.new.call(params)

    if result.success?
      success = result.value!
      relay_state = success.relay_state

      oim_user = success.user
      sign_in(:user, oim_user)

      session[:__saml_name_id] = success.saml_name_id
      session[:__saml_session_index] = success.saml_session_index if success.saml_session_index

      if success.new_user
        if relay_state.blank?
          oim_user.update_attributes!(last_portal_visited: search_insured_consumer_role_index_path)
          redirect_to search_insured_consumer_role_index_path, flash: {notice: "Signed in Successfully."}
        else
          oim_user.update_attributes!(last_portal_visited: relay_state)
          redirect_to URI.parse(relay_state).to_s, flash: {notice: "Signed in Successfully."}
        end
      else
        if !relay_state.blank?
          oim_user.update_attributes!(last_portal_visited: relay_state)
          redirect_to URI.parse(relay_state).to_s, flash: {notice: "Signed in Successfully."}
        elsif !oim_user.last_portal_visited.blank?
          redirect_to URI.parse(oim_user.last_portal_visited).to_s, flash: {notice: "Signed in Successfully."}
        else
          oim_user.update_attributes!(last_portal_visited: search_insured_consumer_role_index_path)
          redirect_to search_insured_consumer_role_index_path, flash: {notice: "Signed in Successfully."}
        end
      end
    else
      failure = result.failure
      case failure.kind
      when :user_expired
        redirect_to account_expired_saml_index_path
      when :invalid_user_data
        log(failure.message, {:severity => failure.severity})
        redirect_to URI.parse(SamlInformation.iam_login_url).to_s, flash: {error: "Invalid User Details."}
      else
        log(failure.message, {:severity => failure.severity})
        render file: 'public/403.html', status: 403
      end
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
end
