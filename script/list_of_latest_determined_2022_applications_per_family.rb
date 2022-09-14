# frozen_string_literal: true

# This script generates a CSV report with information about 2022 Applications and TaxHouseholdsInformation
# rails runner script/list_of_latest_determined_2022_applications_per_family.rb -e production
start_time = DateTime.current
puts "ListOfLatestDetermined2022ApplicationsPerFamily start_time: #{start_time}"
family_ids = Family.where(:"households.tax_households.effective_starting_on".gte => Date.new(2022)).pluck(:id)
total_count = family_ids.count

field_names = %w(PrimaryMemberHBXID ApplicationHbxID AssistanceYear ApplicationAasmState TaxHouseholdsInformation)
file_name = "#{Rails.root}/list_of_latest_determined_2022_applications_per_family.csv"

CSV.open(file_name, 'w', force_quotes: true) do |csv|
  csv << field_names
  family_ids.inject([]) do |_dummy, family_id|
    application = ::FinancialAssistance::Application.where(:aasm_state.in => ['determined', 'imported'], family_id: family_id, assistance_year: 2022).max_by(&:submitted_at)
    primary_person_hbx_id = application&.primary_applicant&.person_hbx_id

    if application.present?
      tax_households = application.eligibility_determinations.inject({}) do |eds_info, eligibility_determination|
        eds_info[eligibility_determination.hbx_assigned_id] = eligibility_determination.applicants.pluck(:person_hbx_id)
        eds_info
      end

      csv << [primary_person_hbx_id, application.hbx_id, application.assistance_year, application.aasm_state, tax_households.to_json]
    else
      csv << [primary_person_hbx_id, 'No 2022 Application', 'N/A', 'N/A', 'N/A', 'N/A']
    end
  rescue StandardError => e
    puts "Unable to process family_id: #{family_id}, message: #{e.message}, backtrace: #{e.backtrace}"
  end
end

puts "Done with the process, total number of family_ids: #{total_count}"
end_time = DateTime.current
puts "ListOfLatestDetermined2022ApplicationsPerFamily end_time: #{end_time}, total_time_taken_in_minutes: #{((end_time - start_time) * 24 * 60).to_f.ceil}"
