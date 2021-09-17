# frozen_string_literal: true

desc "Batch transfer accounts to Medicaid gateway"

task :transfer_accounts => :environment do
  # rake transfer_accounts
  # get the applications submitted daily that are able to be batch transferred or have requested a transfer.
  day = Date.today
  applications = ::FinancialAssistance::Application.determined.where(:submitted_at.gte => day.beginning_of_day).order_by(submitted_at: :desc)
  applications = applications.select(&:is_transferrable?).concat(applications.select(&:transfer_requested))
  applications = applications.group_by(&:family_id).values.map(&:first)

  # transfer accounts
  applications.map(&:transfer_account)
end
