SamlIdp.configure do |config|
#   SamlIdp.config.base = "http://localhost:3000/saml/auth"

  config.x509_certificate = <<-CERT
-----BEGIN CERTIFICATE-----
MIIDNjCCAh4CCQCKVUybLPj81TANBgkqhkiG9w0BAQsFADBdMQswCQYDVQQGEwJJ
TjELMAkGA1UECAwCVFMxDDAKBgNVBAcMA0hZRDESMBAGA1UECgwJUHJpbWVhdXRo
MR8wHQYJKoZIhvcNAQkBFhBoaUBwcmltZWF1dGguY29tMB4XDTE4MDMwMzE2NDcx
NloXDTI4MDIyOTE2NDcxNlowXTELMAkGA1UEBhMCSU4xCzAJBgNVBAgMAlRTMQww
CgYDVQQHDANIWUQxEjAQBgNVBAoMCVByaW1lYXV0aDEfMB0GCSqGSIb3DQEJARYQ
aGlAcHJpbWVhdXRoLmNvbTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEB
AMTR6aba5wB03ARS/WxMu9x1OPSJSMPx36ydo1YGni/+07KwGQttLBONq/ghLCKT
9xf7Y8ZbrYoMGrMWOdUw2TgKDfgogKAK0O3tCKM2jJ09laXHOnzUfNJ7qlKRiHr+
S+xZ0YsKmkuZRkyX86Wy5T2WAxXiV+LKENgLo2gFR2VvWqyNiwOQ7sb3AIkVR1Pz
XswLJ0FJ0Hdgju36KfNGSk7obYouOs5BoXSF7eMzQfwf+Me8SwsFhvhqnm8QSw7y
ecJy6B/nOmYHM6zOynqF//w0B36M93pKQ6WPyal/KfCqo9QkO15ZxIP0QMG/ArD0
nnbYv+PK/apwgxC48ZyBhaMCAwEAATANBgkqhkiG9w0BAQsFAAOCAQEAwzFynT2M
ej0txhiVwhIw7l6E98FGW6tLophUxfLRHn5vopndMCkOFaq6HT03wOAI0mwt1WjL
Z1rTnWebLnn6yq85/l8ZM/nzuYZUx9b7Fa+HcpPTjHgEgfh2Fg55mJcD9xc8MulO
r8TkAK7/vXUCtUCuLBOfwzy450AgfHDRX+iAkt7EM0QETQWpNYqf5n1breQNFes2
XIK2gk/rSrt9lhzT+EqVRS1LaBH0+Iw1RVkh1c9dlysVE6JWmhZ2n0+5GXO40pKP
ksrzXL/50TSpOhpNgh6WC7a72ewS3Ko7XvEcA1xinUuiecYZQ1wPW3JKmC3z68Ar
4I+asfILxPRsSg==
-----END CERTIFICATE-----
  CERT

  config.secret_key = <<-CERT
-----BEGIN RSA PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDE0emm2ucAdNwE
Uv1sTLvcdTj0iUjD8d+snaNWBp4v/tOysBkLbSwTjav4ISwik/cX+2PGW62KDBqz
FjnVMNk4Cg34KICgCtDt7QijNoydPZWlxzp81HzSe6pSkYh6/kvsWdGLCppLmUZM
l/OlsuU9lgMV4lfiyhDYC6NoBUdlb1qsjYsDkO7G9wCJFUdT817MCydBSdB3YI7t
+inzRkpO6G2KLjrOQaF0he3jM0H8H/jHvEsLBYb4ap5vEEsO8nnCcugf5zpmBzOs
zsp6hf/8NAd+jPd6SkOlj8mpfynwqqPUJDteWcSD9EDBvwKw9J522L/jyv2qcIMQ
uPGcgYWjAgMBAAECggEBAIrtcPQqSCx2UGds/R1Y/LIcvFtAHHDTZoM9snGisj5G
rb/PtZ3vLdGPivfW0oSF1UDEXiVByTlMWfxXj/MATBPWZQ3p6QEPIXMQgaxTcOX8
9ojSHGLIymL4j71ApQnMPmNS8yomDcuXIZwnFgC8Sjwyi3MDFe4rm8AkVu+x6jea
KVmxdfXXvPL5SiV6rsg/4snz6AT5ZpQDfREKZtVydv3dpeSYzCdJ6ITYoMPglg5Q
jVNEadPRybvb8xL1B2xc6bK/OjY1pWkdyMjUXgGQFNRli2/Wl1YZkQPDLijIGgjJ
sk9jPUCgxiQbjwhw+LfAB876Sq6kNH38sYvgtBe1wwECgYEA6LwxD8uDwppkNcHK
PLxFFyQhuUbPmqlmGcOJsrxPVKXArd/OGtNsnoPNKFIb22pRE7hSMAfAMgbxyPEB
+W5m23+/vVu9Qf5dwquTsX+gGxAO64jg7Pg4WMMXErumMlwxFLBxs22Ibpngidl5
6hapXHZ98nHxnT3aXnxBusz3pAMCgYEA2H6iY1Dx3RzBjwp4dmZH+UkAPZtf06tC
D5T1opRZJsGLmrsNC5ehXq2C4mgnqOT1MQ2iTVkjNkavcuI4OxXRmZ0p4DSA8Z24
ywnhKpyQ5t4kW4agu/dzbi/EvYDtVquWB9yiDvgzKQpRxAinjK25m2Qb4i5GWxPL
Hcf2j673deECgYEAvAopfcCKMbZ6lvB/jTj0fbEEymTLIgQSaWiSneYGFrdhiVqV
dRkz3pNRNG268jnhThST2xi4EfOIcTlAxh6MXnbGHaG8tVBmwv3L9BLQ8my0EVvj
l7MqG5Vs1AbnTjMsuLGi/DzYibwsLlSXaypqJjnaowOrGse54rN0jBBFWa8CgYBG
tY2aPIzSeBrr+jKAEUX+sI4okP/KZYwNBMz5jdRUaTCMl/1ZxOuKvcca5YPWkPlY
TSiudKegiZOyRRqyiZzMvF06Akv/HlGF1zM4tKxLC1D6p80Ft3t3CJkMf/iEr0Qw
SyqPExe6lsk/6se2leMiUp8cz5phEuTrVC0+npnqYQKBgEBHlTXiFFlkJ023K3Mv
xYg0xGq0puGTGY83hEOjcbyE+NrNjCXXgly8g+MgkPqpMK3vZ9oHZ3/JRNvfi8e1
HuZt5meyj7GkPFQAg/E566H4NZTwFpHt+byOIrqy8ABNu8ITIaE2GS93dR97saqq
+Kxjzwmq9pU25sq3UL93835Z
-----END RSA PRIVATE KEY-----
  CERT

  # config.password = "secret_key_password"
  config.algorithm = :sha1
  # config.organization_name = "Your Organization"
  # config.organization_url = "http://example.com"
  # config.base_saml_location = "#{base}/saml"
  # config.reference_id_generator                                 # Default: -> { UUID.generate }
  # config.attribute_service_location = "#{base}/saml/attributes"
  # config.single_service_post_location = "#{base}/saml/auth"
  config.session_expiry = 86400                                 # Default: 0 which means never

  # Principal (e.g. User) is passed in when you `encode_response`
  #
  config.name_id.formats  =
      {
      "1.1" => {
          unspecified:  ->(principal) { principal.name_id_format },
      },
      "2.0" => {
          transient: -> (principal) { principal.email_address },
          persistent: -> (p) { p.id },
      },
  }

  #   #   OR
  #   #
  #   #   {
  #   #     "1.1" => {
  #   #       email_address: -> (principal) { principal.email_address },
  #   #     },
  #   #     "2.0" => {
  #   #       transient: -> (principal) { principal.email_address },
  #   #       persistent: -> (p) { p.id },
  #   #     },
  #   #   }

  #   # If Principal responds to a method called `asserted_attributes`
  #   # the return value of that method will be used in lieu of the
  #   # attributes defined here in the global space. This allows for
  #   # per-user attribute definitions.
  #   #
  #   ## EXAMPLE **
  #   # class User
  #   #   def asserted_attributes
  #   #     {
  #   #       phone: { getter: :phone },
  #   #       email: {
  #   #         getter: :email,
  #   #         name_format: Saml::XML::Namespaces::Formats::NameId::EMAIL_ADDRESS,
  #   #         conitnue
  # _format: Saml::XML::Namespaces::Formats::NameId::EMAIL_ADDRESS
  #   #       }
  #   #     }
  #   #   end
  #   # end
  #   #
  #   # If you have a method called `asserted_attributes` in your Principal class,
  #   # there is no need to define it here in the config.

  #   # config.attributes # =>
  #   #   {
  #   #     <friendly_name> => {                                                  # required (ex "eduPersonAffiliation")
  #   #       "name" => <attrname>                                                # required (ex "urn:oid:1.3.6.1.4.1.5923.1.1.1.1")
  #   #       "name_format" => "urn:oasis:names:tc:SAML:2.0:attrname-format:uri", # not required
  #   #       "getter" => ->(principal) {                                         # not required
  #   #         principal.get_eduPersonAffiliation                                # If no "getter" defined, will try
  #   #       }                                                                   # `principal.eduPersonAffiliation`, or no values will
  #   #    }                                                                      # be output
  #   #
  #   ## EXAMPLE ##
  #
  config.attributes =
      {
          "MarketIndicator" => {
              "name" => "Market Indicator",
              "name_format" => "urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified",
              "getter" => ->(principal) {
                principal.kind
              }
          },
          "PremiumAmountTotal" => {
              "name" => "Premium Amount Total",
              "name_format" => "urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified",
              "getter" => ->(principal) {
                principal.total_premium.round(2)
              }
          },
          "APTCAmount" => {
              "name" => "APTC Amount",
              "name_format" => "urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified",
              "getter" => ->(principal) {
                principal.applied_aptc_amount.round(2)
              }
          },
          "ProposedCoverageEffectiveDate" => {
              "name" => "Proposed Coverage Effective Date",
              "name_format" => "urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified",
              "getter" => ->(principal) {
                principal.effective_on
              }
          },
          "FirstName" => {
              "name" => "First Name",
              "name_format" => "urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified",
              "getter" => ->(principal) {
                principal.subscriber.person.first_name
              }
          },
          "MiddleName" => {
              "name" => "Middle Name",
              "name_format" => "urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified",
              "getter" => ->(principal) {
                principal.subscriber.person.middle_name
              }
          },
          "LastName" => {
              "name" => "Last Name",
              "name_format" => "urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified",
              "getter" => ->(principal) {
                principal.subscriber.person.last_name
              }
          },
          "SuffixName" => {
              "name" => "Suffix Name",
              "name_format" => "urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified",
              "getter" => ->(principal) {
                principal.subscriber.person.name_sfx
              }
          },
          "StreetName1" => {
              "name" => "Street Name 1",
              "name_format" => "urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified",
              "getter" => ->(principal) {
                principal.subscriber.person.mailing_address.address_1
              }
          },
          "StreetName2" => {
              "name" => "Street Name 2",
              "name_format" => "urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified",
              "getter" => ->(principal) {
                principal.subscriber.person.mailing_address.address_2
              }
          },
          "CityName" => {
              "name" => "City Name",
              "name_format" => "urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified",
              "getter" => ->(principal) {
                principal.subscriber.person.mailing_address.city
              }
          },
          "State" => {
              "name" => "State",
              "name_format" => "urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified",
              "getter" => ->(principal) {
                principal.subscriber.person.mailing_address.state
              }
          },
          "ZipCode" => {
              "name" => "Zip Code",
              "name_format" => "urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified",
              "getter" => ->(principal) {
                principal.subscriber.person.mailing_address.zip
              }
          },
          "ContactEmailAddress" => {
              "name" => "Contact Email Address",
              "name_format" => "urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified",
              "getter" => ->(principal) {
                principal.subscriber.person.work_email_or_best
              }
          },
          "SubscriberIdentifier" => {
              "name" => "Subscriber Identifier",
              "name_format" => "urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified",
              "getter" => ->(principal) {
                principal.subscriber.person.hbx_id
              }
          },

      }
  # config.attributes = {
  #     market_indicator: {
  #         getter: :market_kind,
  #     },
  #     SurName: {
  #         getter: :last_name,
  #     },
  #     Address: {
  #         getter: :user_address,
  #     },
  # }
  #   ## EXAMPLE ##

  #   # config.technical_contact.company = "Example"
  #   # config.technical_contact.given_name = "Jonny"
  #   # config.technical_contact.sur_name = "Support"
  #   # config.technical_contact.telephone = "55555555555"
  #   # config.technical_contact.email_address = "example@example.com"

  service_providers = {
      "some-issuer-url.com/saml" => {
          fingerprint: "EE:A6:1C:13:8C:37:2C:08:55:2D:D6:8F:5C:32:56:A4:BB:95:26:37:12:62:9E:90:43:B1:42:52:0F:31:A0:28",
          metadata_url: "http://some-issuer-url.com/saml/metadata"
      },
  }

#   # `identifier` is the entity_id or issuer of the Service Provider,
#   # settings is an IncomingMetadata object which has a to_h method that needs to be persisted
#   config.service_provider.metadata_persister = ->(identifier, settings) {
#     fname = identifier.to_s.gsub(/\/|:/,"_")
#     FileUtils.mkdir_p(Rails.root.join('cache', 'saml', 'metadata').to_s)
#     File.open Rails.root.join("cache/saml/metadata/#{fname}"), "r+b" do |f|
#       Marshal.dump settings.to_h, f
#     end
#   }

#   # `identifier` is the entity_id or issuer of the Service Provider,
#   # `service_provider` is a ServiceProvider object. Based on the `identifier` or the
#   # `service_provider` you should return the settings.to_h from above
#   config.service_provider.persisted_metadata_getter = ->(identifier, service_provider){
#     fname = identifier.to_s.gsub(/\/|:/,"_")
#     FileUtils.mkdir_p(Rails.root.join('cache', 'saml', 'metadata').to_s)
#     full_filename = Rails.root.join("cache/saml/metadata/#{fname}")
#     if File.file?(full_filename)
#       File.open full_filename, "rb" do |f|
#         Marshal.load f
#       end
#     end
#   }

#   # Find ServiceProvider metadata_url and fingerprint based on our settings
#   config.service_provider.finder = ->(issuer_or_entity_id) do
#     service_providers[issuer_or_entity_id]
#   end
end

