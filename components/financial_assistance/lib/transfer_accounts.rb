# frozen_string_literal: true

module FinancialAssistance
  # Rake task to bulk transfer accounts out
  class TransferAccounts
    def self.run
      # Gets the applications updated in a specified date range that are able to be batch transferred or have requested a transfer.
      # Defaults to current day if no range is specified.
      start_on = ENV['start_on'].present? ? Date.strptime(ENV['start_on'].to_s, "%m/%d/%Y") : Date.yesterday
      end_on = ENV['end_on'].present? ? Date.strptime(ENV['end_on'].to_s, "%m/%d/%Y") : Date.yesterday
      range = start_on.beginning_of_day..end_on.end_of_day
      assistance_year = FinancialAssistanceRegistry[:enrollment_dates].setting(:application_year).item.constantize.new.call.value!.to_s

      eligible_family_ids = ::FinancialAssistance::Application.determined.where(submitted_at: range, assistance_year: assistance_year).distinct(:family_id)
      transferred_apps = []
      eligible_family_ids.each do |family_id|
        application = FinancialAssistance::Application.where(family_id: family_id, assistance_year: assistance_year, aasm_state: 'determined').last
        if application.present? && (application.transfer_requested || application.is_transferrable?) && !application.account_transferred
          application.transfer_account
          transferred_apps << application.hbx_id
        end
      end
      transferred_apps
    end
  end
end