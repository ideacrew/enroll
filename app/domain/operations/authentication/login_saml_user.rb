# frozen_string_literal: true

module Operations
  module Authentication
    # Login a user from a SAML IDP payload and request.
    class LoginSamlUser
      include Dry::Monads[:do, :result]

      def call(request_params)
        saml_settings = yield ConstructSamlSettings.new.call
        construct_saml_response(saml_settings, request_params)
        saml_token_result = yield construct_saml_response(saml_settings, request_params)
        existing_user = yield find_existing_user(saml_token_result)
        if existing_user
          update_existing_user(existing_user, saml_token_result)
        else
          create_new_user(saml_token_result)
        end
      end

      protected

      def update_existing_user(existing_user, saml_token_result)
        response = saml_token_result[:saml_response]

        existing_user.idp_verified = true
        existing_user.oim_id = response.name_id

        unless existing_user.valid?
          return Failure(
            Entities::Authentication::SamlAuthenticationFailure.new(
              {
                kind: :invalid_user_data,
                message: "ERROR: #{existing_user.errors.messages}",
                severity: "error"
              }
            )
          )
        end

        existing_user.save!
        update_navigation_flag(existing_user.oim_id, response.attributes['mail'])

        build_auth_success(existing_user, false, saml_token_result)
      end

      def create_new_user(saml_token_result)
        response = saml_token_result[:saml_response]

        new_password = User.generate_valid_password
        new_email = response.attributes['mail'].present? ? response.attributes['mail'] : ""

        headless = User.where(email: /^#{Regexp.escape(new_email)}$/i).first
        headless.destroy if headless.present? && !headless.person.present?
        new_user = User.new(email: new_email, password: new_password, idp_verified: true, oim_id: response.name_id)

        unless new_user.valid?
          return Failure(
            Entities::Authentication::SamlAuthenticationFailure.new(
              {
                kind: :invalid_user_data,
                message: "ERROR: #{new_user.errors.messages}",
                severity: "error"
              }
            )
          )
        end

        new_user.save!

        update_navigation_flag(response.name_id, response.attributes['mail'])

        build_auth_success(new_user, true, saml_token_result)
      end

      def find_existing_user(saml_token_result)
        username = saml_token_result[:saml_response].name_id.downcase
        found_user = User.where(oim_id: /^#{Regexp.escape(username)}$/i).first

        return Success(found_user) unless found_user&.expired?

        Failure(
          Entities::Authentication::SamlAuthenticationFailure.new(
            {
              kind: :user_expired,
              message: "User Expired",
              severity: "error"
            }
          )
        )
      end

      def construct_saml_response(saml_settings, request_params)
        response          = OneLogin::RubySaml::Response.new(request_params[:SAMLResponse], :allowed_clock_drift => 5.seconds)
        response.settings = saml_settings

        relay_state = request_params['RelayState'] || response.attributes['relay_state']

        if response.is_valid? && response.name_id.present?
          Success(
            {
              saml_response: response,
              relay_state: relay_state,
              saml_session_index: response.sessionindex,
              saml_name_id: response.name_id
            }
          )
        elsif !response.name_id.present?
          Failure(
            Entities::Authentication::SamlAuthenticationFailure.new(
              {
                kind: :invalid_token,
                message: "ERROR: SAMLResponse has missing required mail attribute",
                severity: "critical"
              }
            )
          )
        else
          Failure(
            Entities::Authentication::SamlAuthenticationFailure.new(
              {
                kind: :invalid_token,
                message: "ERROR: SAMLResponse assertion errors #{response.errors}",
                severity: "error"
              }
            )
          )
        end
      end

      def build_auth_success(user, new_user, saml_token_result)
        Success(
          Entities::Authentication::SamlAuthenticationSuccess.new(
            {
              user: user,
              new_user: new_user,
              relay_state: saml_token_result[:relay_state],
              saml_session_index: saml_token_result[:saml_session_index],
              saml_name_id: saml_token_result[:saml_name_id]
            }
          )
        )
      end

      def update_navigation_flag(account_id, mail)
        ::IdpAccountManager.update_navigation_flag(
          account_id,
          mail,
          ::IdpAccountManager::ENROLL_NAVIGATION_FLAG
        )
      end
    end
  end
end