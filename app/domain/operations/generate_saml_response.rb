# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  # Call SamGenerator to generate a SAML response
  class GenerateSamlResponse
    include Dry::Monads[:result, :do]

    def call(params)
      values               = yield validate(params)
      hbx_enrollment       = yield enrollment(values)
      payment_transaction  = yield create_payment_transaction(hbx_enrollment, values)
      saml_object          = yield init_saml_generator(payment_transaction, hbx_enrollment)
      saml_response        = yield build_saml_response(saml_object)
      result               = yield encode_saml_reponse(saml_object, saml_response)

      Success(result)
    end

    private

    def validate(params)
      return Failure("Given input is not a valid enrollment id") unless params[:enrollment_id].is_a?(String)
      return Failure("Given input is not a valid source kind") unless params[:source].is_a?(String)
      Success(params)
    end

    def enrollment(values)
      enrollment = ::HbxEnrollment.by_hbx_id(values[:enrollment_id]).first
      enrollment ? Success(enrollment) : Failure("Enrollment Not Found")
    end

    def create_payment_transaction(hbx_enrollment, values)
      Operations::PaymentTransactions::Create.new.call({hbx_enrollment: hbx_enrollment, source: values[:source]})
    end

    def init_saml_generator(payment_transaction, hbx_enrollment)
      saml_obj = OneLogin::RubySaml::SamlGenerator.new(payment_transaction.payment_transaction_id, hbx_enrollment)
      saml_obj ? Success(saml_obj) : Failure('Unable to initialize OneLogin::RubySaml::SamlGenerator.')
    end

    def build_saml_response(saml_object)
      result = saml_object.build_saml_response
      result ? Success(result) : Failure('Unable to build saml response for given SamlGenerator object.')
    end

    def encode_saml_reponse(saml_object, saml_response)
      response = saml_object.encode_saml_response(saml_response)
      Success({'SAMLResponse': response})
    end
  end
end