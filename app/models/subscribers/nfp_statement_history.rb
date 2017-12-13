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

        response = eval(xml)

        ep = Organization.where("hbx_id" => eid).first

        if ep && ep.employer_profile
          employer_profile_account = ep.employer_profile.employer_profile_account || ep.employer_profile.build_employer_profile_account
          employer_profile_account.update_attributes!(
           :next_premium_due_on => TimeKeeper.date_of_record, # just a random date, not currently being used.
           :past_due => response[:past_due],
           :adjustments => response[:adjustments],
           :payments => response[:payments],
           :total_due => response[:total_due],
           :previous_balance => response[:previous_balance],
           :new_charges => response[:new_charges],
           :current_statement_date => Date.strptime(response[:statement_date], "%m/%d/%Y")
           )

           employer_profile_account.current_statement_activity.destroy_all
           employer_profile_account.premium_payments.destroy_all

           response[:adjustment_items].each do |line|
             csa = CurrentStatementActivity.new
             csa.description = line[:description]
             csa.name = line[:name]
             csa.amount = line[:amount]
             csa.posting_date = Date.strptime(line[:posting_date], "%m/%d/%Y")
             csa.type = line[:type]
             csa.coverage_month = line[:coverage_month]
             csa.payment_method = line[:payment_method]
             employer_profile_account.current_statement_activity << csa
             csa.save
           end

           response[:payment_history].each do |payment|
             p = PremiumPayment.new
             p.paid_on = payment[:paid_on]
             p.reference_id = payment[:reference_id]
             p.method_kind = payment[:method_kind]
             p.amount = payment[:amount]
             employer_profile_account.premium_payments << p
             p.save
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
