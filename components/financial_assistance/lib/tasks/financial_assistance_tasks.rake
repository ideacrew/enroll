# frozen_string_literal: true

desc "Batch transfer accounts to Medicaid gateway"
task :transfer_accounts => :environment do
  # Example rake command with start and end dates:
  # rake transfer_accounts start_on="01/01/2021" end_on="01/31/2021"
  # Gets the applications determined in a specified date range that are able to be batch transferred or have requested a transfer.
  # Defaults to current day if no range is specified.
  start_on = ENV['start_on'].present? ? Date.strptime(ENV['start_on'].to_s, "%m/%d/%Y") : Date.yesterday
  end_on = ENV['end_on'].present? ? Date.strptime(ENV['end_on'].to_s, "%m/%d/%Y") : Date.yesterday
  range = start_on.beginning_of_day..end_on.end_of_day

  # Only get applications that were submitted on or after the start_on date
  ::FinancialAssistance::Application.determined \
                                    .where(:submitted_at.gte => start_on) \
                                    .map {|a| a.active_determined_eligibility_determinations.order_by(determined_at: :desc).first} \
                                    .select {|ed| !ed.nil? && range.include?(ed.determined_at) }.map(&:application) \
                                    .group_by(&:family_id).values.map(&:first) \
                                    .select { |a| a.is_transferrable? || a.transfer_requested} \
                                    .map(&:transfer_account)
end