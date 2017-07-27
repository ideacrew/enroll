module Subscribers
  class NfpStatementHistory < ::Acapi::Subscription
    include Acapi::Notifiers

    def self.subscription_details
      ["acapi.info.events.employer.nfp_statement_summary_success"]
    end

    def call(event_name, e_start, e_end, msg_id, payload)
      process_response(payload)
    end

    private
    def process_response(payload)
      begin
        stringed_key_payload = payload.stringify_keys
        xml = stringed_key_payload['body']
        header = stringed_key_payload['header']

        Rails.logger.info "==================="
        Rails.logger.info "Enroll received nfp_statement_summary_success"
        Rails.logger.info xml.to_s
        Rails.logger.info stringed_key_payload.to_s
        Rails.logger.info "==================="

        # ep = Organization.where("hbx_id" = > header[:customer_id]).first.employer_profile
        # ep.employer_profile_account.next_premium_amount = 9999

        #TODO change response handler
        if "503" == return_status.to_s

          return
        end

        xml_hash = xml_to_hash(xml)

      rescue => e
        notify("acapi.error.application.enroll.remote_listener.nfp_statement_history_responses", {
          :body => JSON.dump({
             :error => e.inspect,
             :message => e.message,
             :backtrace => e.backtrace
          })})
      end
    end

  end
end
