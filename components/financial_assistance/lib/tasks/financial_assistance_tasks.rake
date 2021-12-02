# frozen_string_literal: true

require "#{Rails.root}/components/financial_assistance/lib/transfer_accounts"

desc "Batch transfer accounts to Medicaid gateway"
 # Example rake command with start and end dates:
 # rake transfer_accounts start_on="01/01/2021" end_on="01/31/2021"
task :transfer_accounts => :environment do
  ::FinancialAssistance::TransferAccounts.run
end