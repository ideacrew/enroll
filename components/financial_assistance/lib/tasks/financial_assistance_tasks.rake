# frozen_string_literal: true

desc "Batch transfer accounts to Medicaid gateway"

task :transfer_accounts => :environment do
  # Example rake command with start and end dates:
  # rake transfer_accounts start_on="01/01/2021" end_on="01/31/2021"
  # Gets the applications submitted in a specified date range that are able to be batch transferred or have requested a transfer.
  # Defaults to current day if no range is specified.

  start_on = ENV['start_on'].present? ? Date.strptime(ENV['start_on'].to_s, "%m/%d/%Y") : Date.today
  end_on = ENV['end_on'].present? ? Date.strptime(ENV['end_on'].to_s, "%m/%d/%Y") : Date.today
  range = start_on.beginning_of_day..end_on.end_of_day

  applications = ::FinancialAssistance::Application.determined.where(submitted_at: range).order_by(submitted_at: :desc)
  applications = applications.select(&:is_transferrable?).concat(applications.select(&:transfer_requested))
  applications = applications.group_by(&:family_id).values.map(&:first)

  # transfer accounts
  applications.map(&:transfer_account)
end
