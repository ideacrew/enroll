# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  # Call SamlGenerator to generate a SAML response
  class GenerateSamlResponse
    include Dry::Monads[:do, :result]

    def call(params)
      values               = yield validate(params)
      hbx_enrollment       = yield enrollment(values)
      payment_transaction  = yield create_payment_transaction(hbx_enrollment, values[:source])
      saml_object          = yield init_saml_generator(payment_transaction, hbx_enrollment)
      saml_response        = yield build_saml_response(saml_object)
      _validated_saml      = yield validate_saml_response(saml_response)
      result               = yield encode_saml_reponse(saml_object, saml_response)

      Success(result)
    end

    private

    def validate(params)
      return Failure("Given input is not a valid enrollment id") unless params[:enrollment_id].is_a?(String)
      Success(params)
    end

    def enrollment(values)
      enrollment = ::HbxEnrollment.by_hbx_id(values[:enrollment_id]).first
      enrollment ? Success(enrollment) : Failure("Enrollment Not Found")
    end

    def create_payment_transaction(hbx_enrollment, source)
      payment = PaymentTransaction.build_payment_instance(hbx_enrollment, source)
      payment ? Success(payment) : Failure("Issue with Payment transcation")
    end

    def init_saml_generator(payment_transaction, hbx_enrollment)
      saml_obj = OneLogin::RubySaml::SamlGenerator.new(payment_transaction.payment_transaction_id, hbx_enrollment)
      saml_obj ? Success(saml_obj) : Failure('Unable to initialize OneLogin::RubySaml::SamlGenerator.')
    end

    def build_saml_response(saml_object)
      result = saml_object.build_saml_response
      result ? Success(result) : Failure('Unable to build saml response for given SamlGenerator object.')
    end

    def validate_saml_response(saml_response)
      return Success(:ok) unless EnrollRegistry.feature_enabled?(:validate_saml)
      #replace character entities with valid characters that can be parsed by validator
      decoded_saml = decode_character_entities(saml_response.to_s)
      AcaEntities::Serializers::Xml::PayNow::CareFirst::Operations::ValidatePayNowTransferPayloadSaml.new.call(decoded_saml)
    end

    def decode_character_entities(saml_response)
      character_entities = {
        '&amp;' => '&',
        '&quot;' => '"',
        '&apos;' => "'",
        '&lt;' => '<',
        '&gt;' => '>'
      }
      character_entities.inject(saml_response) do |decoded_saml, decoder|
        decoded_saml.gsub(decoder[0], decoder[1])
      end
    end

    def encode_saml_reponse(saml_object, saml_response)
      response = saml_object.encode_saml_response(saml_response)
      Success({'SAMLResponse': response})
    end
  end
end
