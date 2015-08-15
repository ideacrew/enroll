module IdentityVerification
  class InteractiveVerificationService
    class SlugRequestor
      def request(key, opts, timeout)
        case key.to_s
        when "identity_verification.interactive_verification.initiate_session"
          { :return_status => 200, :body => File.read(File.join(Rails.root, "spec", "test_data", "ridp_payloads", "successful_start_response.xml")) }
        when "identity_verification.interactive_verification.respond_to_questions"
          { :return_status => 200, :body => File.read(File.join(Rails.root, "spec", "test_data", "ridp_payloads", "successful_question_response.xml")) }
        else
          raise "I don't understand this request!"
        end
      end
    end

    def self.slug!
      set_requestor(SlugRequestor)
    end

    def self.set_requestor(val)
      @@requestor = val
    end

    def self.requestor
      @@requestor ||= Acapi::Requestor
    end

    def initiate_session(payload)
      # Configured with a timeout of 5, we can extend it
      code, body = invoke_request("identity_verification.interactive_verification.initiate_session", payload, 5)
      return nil if code == "503"
      IdentityVerification::InteractiveVerificationResponse.parse(body, :single => true)
    end

    def respond_to_questions(payload)
      # Configured with a timeout of 5, we can extend it
      code, body = invoke_request("identity_verification.interactive_verification.respond_to_questions", payload, 5)
      return nil if code == "503"
      IdentityVerification::InteractiveVerificationResponse.parse(body, :single => true)
    end

    def invoke_request(key, payload, timeout)
      begin
        r = self.class.requestor.request("identity_verification.interactive_verification.initiate_session", {:body => payload}, 5)
        return ["503", nil] if r.nil?
        result_hash = r.stringify_keys
        result_code = result_hash["return_status"]
        case result_code.to_s
        when "503"
          ["503", nil] 
        else
          [result_code.to_s, r["body"]]
        end
      rescue Timeout::Error => e
        ["503", nil]
      end
    end
  end
end

if !Rails.env.production?
  ::IdentityVerification::InteractiveVerificationService.slug!
end
