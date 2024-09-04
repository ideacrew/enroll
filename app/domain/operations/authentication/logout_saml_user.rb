# frozen_string_literal: true

module Operations
  module Authentication
    # Do any work needed outside of just killing the devise session to log out
    # a SAML-based user.
    class LogoutSamlUser

      include Dry::Monads[:do, :result, :try]

      def call(session)
        saml_settings = yield ConstructSamlSettings.new.call
        saml_logout_xml = yield construct_saml_request_xml(saml_settings, session)
        logout_url = yield parse_logout_service_url(saml_settings)
        post_saml_logout_xml(logout_url, saml_logout_xml)
      end

      protected

      def construct_saml_request_xml(settings, session)
        name_id = session[:__saml_name_id]
        saml_session_index = session[:__saml_session_index]
        return Failure("No SAML NameID available") if name_id.blank?
        request = OneLogin::RubySaml::Logoutrequest.new
        settings.name_identifier_value = name_id
        settings.sessionindex = saml_session_index unless saml_session_index.blank?
        Success(request.create_logout_request_xml_doc(settings))
      end

      def parse_logout_service_url(saml_settings)
        logout_url = saml_settings.idp_slo_service_url

        parse_result = Try do
          URI.parse(logout_url)
        end.or(Failure("Invalid SAML logout service URI"))

        return parse_result unless parse_result.success?

        parsed_url = parse_result.value!

        return Failure("Empty SAML service path") if parsed_url.path.blank?

        Success(parsed_url)
      end

      def post_saml_logout_xml(logout_url, saml_logout_xml)
        logger = Rails.logger
        request = Net::HTTP::Post.new logout_url.path
        request.body = saml_logout_xml.to_s
        request.content_type = 'text/xml'
        result = Try do
          Net::HTTP.start(logout_url.hostname, logout_url.port, :use_ssl => logout_url.scheme == 'https') { |http| http.request request }
        end.to_result
        logger.tagged("SAMLLogoutAttempt") do
          if result.success?
            response = result.value!
            unless (200..299).include?(response.code.to_i)
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