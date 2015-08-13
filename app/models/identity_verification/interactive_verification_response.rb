module IdentityVerification
  class InteractiveVerificationResponse
    include HappyMapper
    register_namespace 'acapi', 'http://openhbx.org/api/terms/1.0'

    tag 'interactive_verification_result'
    namespace 'acapi'

    element 'verification_result', "IdentityVerification::InteractiveVerificationResult"

    element "session", "IdentityVerification::InteractiveVerificationSession"

    def failed?
      "urn:openhbx:terms:v1:interactive_identity_verification#FAILURE" == response_code
    end

    def response_code
      either_child_property(:response_code)
    end

    def response_text
      return nil if verification_result.nil?
      verification_result.response_text
    end

    def transaction_id
      either_child_property(:transaction_id)
    end

    def either_child_property(prop, default_prop_val = nil)
      return(session.send(prop)) unless session.nil?
      return(verification_result.send(prop)) unless verification_result.nil?
      default_prop_val
    end

    def questions
      return [] if session.nil?
      session.questions
    end

    def session_id
      return nil if session.nil?
      session.session_id
    end

    def continue_session?
      !session.nil?
    end
  end
end
