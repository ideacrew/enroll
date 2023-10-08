# frozen_string_literal: true

# Report to find applications for renewal year which failed to generate in renewal_draft state

# bundle exec rails r script/renewal_draft_blocker_reasons_report.rb '2024'

require 'csv'

assistance_year = ARGV[0].present? && ARGV[0].respond_to?(:to_i) ? ARGV[0].to_i : TimeKeeper.date_of_record.year

applications = ::FinancialAssistance::Application.by_year(assistance_year).where(
  :aasm_state.in => ['applicants_update_required', 'income_verification_extension_required']
)

file_name = "renewal_draft_blocker_reasons_report_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv"

CSV.open(file_name, 'w', force_quotes: true) do |csv|
  csv << [
    'Application Hbx ID',
    'Application Assistance Year',
    'Application Aasm State',
    'Application Renewal Draft Blocker Reason(s)'
  ]

  applications.each do |application|
    csv << [
      application.hbx_id,
      application.assistance_year,
      application.aasm_state,
      application.renewal_draft_blocker_reasons.join(', ')
    ]
  end
end
