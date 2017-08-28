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


        Rails.logger.info "BEGIN **********===================**********"
        Rails.logger.info "Enroll received nfp_statement_summary_success"
        Rails.logger.info xml
        Rails.logger.info stringed_key_payload
        Rails.logger.info "Employer id: #{eid}"
        Rails.logger.info "END **********===================**********"

        response = eval(xml)

        ep = Organization.where("hbx_id" => eid).first

        if ep.employer_profile
          employer_profile_account = ep.employer_profile.employer_profile_account || ep.employer_profile.build_employer_profile_account
          employer_profile_account.update_attributes!(:next_premium_due_on => Date.today,
           :message => response[:message],
           :past_due => response[:past_due],
           :adjustments => response[:adjustments],
           :payments => response[:payments],
           :total_due => response[:total_due]
           )

           employer_profile_account.current_statement_activity.destroy_all
           response[:adjustment_items].each do |line|
             csa = CurrentStatementActivity.new
             csa.description = line[:description]
             csa.name = line[:name]
             csa.amount = line[:amount]
             csa.posting_date = line[:posting_date]
             csa.type = line[:type]
             employer_profile_account.current_statement_activity << csa
             csa.save
           end

        end

      rescue => e
        Rails.logger.error e.message
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
