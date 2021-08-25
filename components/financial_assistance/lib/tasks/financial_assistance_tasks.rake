# frozen_string_literal: true

desc "Batch transfer accounts to Medicaid gateway"
task :transfer_accounts do
  return unless FinancialAssistanceRegistry.feature_enabled?(:batch_transfer)
  day = "Mon, 7 Jun 2021 19:41:15 +0000".to_datetime
  # since none created today I'm just leaving this commented for now while testing
  # day = Date.today
  applications = ::FinancialAssistance::Application.submitted.where(:submitted_at.gte => day.beginning_of_day).order_by(submitted_at: :desc)
  applications.group_by(&:family_id).values.map(&:first).map(&:transfer_account)
end
