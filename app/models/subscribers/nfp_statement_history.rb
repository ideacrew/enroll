# frozen_string_literal: true

module Subscribers
  class NfpStatementHistory < ::Acapi::Subscription
    include Acapi::Notifiers

    def self.subscription_details
      ["acapi.info.events.employer.nfp_statement_summary_success"]
    end

    def call(_event_name, _e_start, _e_end, _msg_id, payload)
      process_response(payload)
    end

    private

    def process_response(payload)
      stringed_key_payload = payload.stringify_keys
      json_body = stringed_key_payload['body']
      eid = stringed_key_payload['employer_id']
      response = JSON.parse(json_body)
      begin
        organization = BenefitSponsors::Organizations::Organization.where("hbx_id" => eid).first
        benefit_sponsorship = organization.benefit_sponsorships.first

        if organization.present? && organization.employer_profile
          benefit_sponsorship_account = benefit_sponsorship.benefit_sponsorship_account || benefit_sponsorship.build_benefit_sponsorship_account
          benefit_sponsorship_account.update_attributes!(
            :next_premium_due_on => TimeKeeper.date_of_record, # just a random date, not currently being used.
            :past_due => response["past_due"],
            :adjustments => response["adjustments"],
            :payments => response["payments"],
            :total_due => response["total_due"],
            :previous_balance => response["previous_balance"],
            :new_charges => response["new_charges"],
            :current_statement_date => Date.strptime(response["statement_date"], "%m/%d/%Y")
          )
          benefit_sponsorship_account.current_statement_activities.destroy_all
          benefit_sponsorship_account.financial_transactions.destroy_all
          update_current_statement_activities(response["adjustment_items"], benefit_sponsorship_account)
          update_financial_transactions(response["payment_history"], benefit_sponsorship_account)
        end
      rescue StandardError => e
        Rails.logger.error e.message
        notify(
          "acapi.error.application.enroll.remote_listener.nfp_statement_history_responses",
          {
            :body => JSON.dump(
              {
                :error => e.inspect,
                :message => e.message,
                :backtrace => e.backtrace
              }
            )
          }
        )
      end
    end

    def update_current_statement_activities(params, benefit_sponsorship_account)
      params.each do |line|
        csa = BenefitSponsors::BenefitSponsorships::CurrentStatementActivity.new
        csa.description = line["description"]
        csa.name = line["name"]
        csa.amount = line["amount"]
        csa.posting_date = Date.strptime(line["posting_date"], "%m/%d/%Y")
        csa.type = line["type"]
        csa.coverage_month = line["coverage_month"]
        csa.payment_method = line["payment_method"]
        csa.is_passive_renewal = line["is_passive_renewal"]
        benefit_sponsorship_account.current_statement_activities << csa
        csa.save
      end
    end

    def update_financial_transactions(params, benefit_sponsorship_account)
      params.each do |payment|
        ft = BenefitSponsors::BenefitSponsorships::FinancialTransaction.new
        ft.paid_on = payment["paid_on"]
        ft.reference_id = payment["reference_id"]
        ft.method_kind = payment["method_kind"]
        ft.amount = payment["amount"]
        benefit_sponsorship_account.financial_transactions << ft
        ft.save
      end
    end
  end
end
