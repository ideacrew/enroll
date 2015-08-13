module IdentityVerification
  class InteractiveVerificationResult
    include HappyMapper

    register_namespace 'acapi', 'http://openhbx.org/api/terms/1.0'
    tag 'verification_result'
    namespace 'acapi'

    element 'response_code', String
    element 'response_text', String
    element 'transaction_id', String

    def failed?
      "urn:openhbx:terms:v1:interactive_identity_verification#FAILURE" == response_code
    end
  end
end
