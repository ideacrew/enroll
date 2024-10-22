# frozen_string_literal: true

# DO NOT run this script in production without proper approvals.

def field_names
  %w[primary_hbx_id
     application_hbx_id
     created_at
     aasm_state
     assistance_year
     is_renewal_authorized
     renewal_base_year
     current_years_to_renew
     new_years_to_renew
     deleted_2025_application_hbx_ids]
end

file_name = "#{Rails.root}/years_to_renew_cleanup_2024.csv"

# hard coding the year to 2024 in query to avoid any confusion
impacted_applications = ::FinancialAssistance::Application.where(is_renewal_authorized: true, :years_to_renew => nil, assistance_year: 2024, aasm_state: 'determined')

CSV.open(file_name, "w", force_quotes: true) do |csv|
  csv << field_names
  impacted_applications.no_timeout.each do |application|

    application_hbx_id = application.hbx_id
    current_years_to_renew = application.years_to_renew
    application.set(years_to_renew: 5, updated_at: Time.zone.now) # avoiding call backs
    renewal_applications = ::FinancialAssistance::Application.where(predecessor_id: application.id, aasm_state: 'income_verification_extension_required')
    deleted_2025_application_hbx_ids = renewal_applications&.pluck(:hbx_id)
    renewal_applications&.destroy_all # Have specific requirment for this from lead and product owner.

    csv << [application.family&.primary_applicant&.person&.hbx_id,
            application_hbx_id,
            application.created_at,
            application.aasm_state,
            application.assistance_year,
            application.is_renewal_authorized,
            application.renewal_base_year,
            current_years_to_renew,
            application.years_to_renew,
            deleted_2025_application_hbx_ids]
    puts "updated years_to_renew for #{application_hbx_id} and deleted renewal in income_verification_extension_required state" unless Rails.env.test?
  rescue StandardError => e
    puts "Cannot process application with id: #{application_hbx_id}, error: #{e.backtrace}"
  end
end