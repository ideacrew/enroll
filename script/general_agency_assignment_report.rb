require 'csv'

batch_size = 500
offset = 0

orgs = BenefitSponsors::Organizations::Organization.employer_profiles
org_count = orgs.count
field_names  = %w(
           Group_name
           Employer_FEIN
           General_Agency_Name
           General_Agency_Staff_Name
           Agency_NPN
           Assignment_start_date
           Assignment_end_date
           )

processed_count = 0
file_name = "#{Rails.root}/ga_assignment_report_#{TimeKeeper.date_of_record.strftime("%m_%d_%Y")}.csv"

CSV.open(file_name, "w", force_quotes: true) do |csv|
  csv << field_names

  while offset <= org_count
    orgs.offset(offset).limit(batch_size).no_timeout.each do |org|
      employer = org.employer_profile
      employer.general_agency_accounts&.each do |ga_account|
        next if ga_account.nil? || ga_account.general_agency_profile.nil? || ga_account.general_agency_profile.market_kind.to_s == "individual"

        ga_staff_role = ga_account.general_agency_profile.general_agency_staff_roles.first
        csv << [
          employer.legal_name,
          employer.fein,
          ga_account.general_agency_profile.legal_name,
          ga_staff_role.person.full_name,
          ga_staff_role.npn,
          ga_account.start_on,
          ga_account.end_on
        ]
      end
      processed_count += 1
    end
    offset = offset + batch_size
  end
  puts "Processed #{processed_count} general agencies to output file: #{file_name}" unless Rails.env.test?
end
