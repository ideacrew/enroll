# frozen_string_literal: true

module Operations
  module Authentication
    # Do any work needed outside of just killing the devise session to log out
    # a SAML-based user.
    class LogoutSamlUser

      include Dry::Monads[:do, :result, :try]

      def call(session)
        saml_settings = yield ConstructSamlSettings.new.call
        saml_logout_url = yield construct_saml_request(saml_settings, session)
        execute_saml_logout(saml_logout_url)
      end

      protected

      def construct_saml_request(settings, session)
        name_id = session[:__saml_name_id]
        saml_session_index = session[:__saml_session_index]
        return Failure("No SAML NameID available") if name_id.blank?
        request = OneLogin::RubySaml::Logoutrequest.new
        settings.name_identifier_value = name_id
        settings.sessionindex = saml_session_index unless saml_session_index.blank?
        Try do
          request.create(settings)
        end.to_result
      end

      def execute_saml_logout(saml_logout_url)
        logger = Rails.logger

        result = Try do
          saml_url = URI(saml_logout_url)
          http = Net::HTTP.new(saml_url.host, saml_url.port)
          http.use_ssl = saml_url.scheme == 'https'
          http.get(saml_url.request_uri)
        end.to_result
        logger.tagged("SAMLLogoutAttempt") do
          if result.success?
            response = result.value!
            unless (200..299).include?(response.code.to_i) || (300..399).include?(response.code.to_i)
              logger.error "Status: #{response.code}"
              logger.error "Body:\n#{response.body}"
            end
          end
        end
        result
      end
    end
  end
end