# frozen_string_literal: true

module FinancialAssistance
  # Rake task to bulk transfer accounts out
  class TransferAccounts
    include Dry::Monads[:do, :result]
    include EventSource::Command
    include EventSource::Logging

    def self.run
      # Gets the applications updated in a specified date range that are able to be batch transferred or have requested a transfer.
      # Defaults to current day if no range is specified.
      new.transfer_accounts
    end

    def transfer_accounts
      start_on = ENV['start_on'].present? ? Date.strptime(ENV['start_on'].to_s, "%m/%d/%Y") : Date.yesterday
      end_on = ENV['end_on'].present? ? Date.strptime(ENV['end_on'].to_s, "%m/%d/%Y") : Date.yesterday
      range = start_on.beginning_of_day..end_on.end_of_day
      eligible_family_ids = ::FinancialAssistance::Application.determined_and_submitted_within_range(range).distinct(:family_id)
      families = Family.where(:_id.in => eligible_family_ids)
      build_account_transfer_requests(families)
    end

    def build_account_transfer_requests(families)
      account_transfer_logger = Logger.new("#{Rails.root}/log/account_transfer_logger_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
      count = 0
      total_families_count = families.count
      account_transfer_logger.info("********************************* Total families with determined applications count #{total_families_count}  *********************************")
      families.no_timeout.each_with_index do |family, index|
        application = FinancialAssistance::Application.for_determined_family(family.id).last
        if application.present? && (application.transfer_requested || application.is_transferrable?) && !application.account_transferred
          publish_event(application, index)
          account_transfer_logger.info("********************************* processed application #{application.hbx_id}  *********************************") if count % 100 == 0
        end
        count += 1
        account_transfer_logger.info("********************************* processed #{count} families *********************************") if count % 100 == 0
      rescue StandardError => e
        account_transfer_logger.error("failed to process for family with hbx_id #{family.hbx_assigned_id} due to #{e.inspect}")
      end
    end

    def publish_event(application, index)
      payload = { application_id: application.id, index: index }
      event = build_event(payload)
      event.success.publish
    end

    def build_event(payload)
      event('events.iap.account_transfers.requested', attributes: payload)
    end
  end
end
