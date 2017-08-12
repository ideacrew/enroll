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
        eid = stringed_key_payload['employer_id']


        Rails.logger.info "**********===================**********"
        Rails.logger.info "Enroll received nfp_statement_summary_success"
        Rails.logger.info xml
        Rails.logger.info stringed_key_payload
        Rails.logger.info eid

        response = eval(xml)

        ep = Organization.where("hbx_id" => eid).first

        if ep.employer_profile && ep.employer_profile.employer_profile_account
          ep.employer_profile.employer_profile_account.update_attributes!(:next_premium_due_on => Date.today,
           :next_premium_amount => response[:new_charges].to_f,
           :message => response[:message],
           :past_due => response[:past_due],
           :adjustments => response[:adjustments],
           :payments => response[:payments],
           :total_due => response[:total_due]
           )
        end

      rescue => e
        puts "ERROR ERROR ERROR"
        puts e
        Rails.logger.info e
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
