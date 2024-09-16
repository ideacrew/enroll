# frozen_string_literal: true

module Operations
  module Authentication
    # Construct a set of SAML settings from our configuration
    class ConstructSamlSettings
      include Dry::Monads[:do, :result]

      def call(_params = {})
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

        if EnrollRegistry.feature_enabled?(:saml_single_logout)
          settings.idp_slo_service_url = SamlInformation.idp_slo_target_url
          settings.sp_entity_id = EnrollRegistry[:saml_single_logout].setting(:saml_sp_name).item
          sp_cert = EnrollRegistry[:saml_single_logout].setting(:saml_sp_certificate).item
          sp_pk = EnrollRegistry[:saml_single_logout].setting(:saml_sp_private_key).item
          settings.idp_slo_service_binding = "redirect"
          unless sp_cert.blank? || sp_pk.blank?
            settings.private_key = sp_pk
            settings.certificate = sp_cert
            settings.security.logout_requests_signed = true
          end
        end

        Success(settings)
      end
    end
  end
end