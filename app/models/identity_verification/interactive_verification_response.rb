module IdentityVerification
  class InteractiveVerificationResponse
    include HappyMapper
    register_namespace 'acapi', 'http://openhbx.org/api/terms/1.0'

    tag 'interactive_verification_result'
    namespace 'acapi'

    element 'verification_result', "IdentityVerification::InteractiveVerificationResult"

    def failed?
      return false if verification_result.nil?
      verification_result.failed?
    end

    def response_text
      verification_result.response_text
    end

    def transaction_id
      verification_result.transaction_id
    end
  end
end
