# frozen_string_literal: true

require 'csv'
organization_field_names = %w[OrganizationLegalName FEIN HbxID Role ContactMethod]
organization_file_name = "#{Rails.root}/organization_role_contact_method_report#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv"
puts "Start of rake, time: #{Time.zone.now}"
CSV.open(organization_file_name, 'w', force_quotes: true) do |csv|
  csv << organization_field_names
  ::BenefitSponsors::Organizations::Organization.employer_profiles.inject([]) do |tt, organization|
    begin
      csv << [organization.legal_name,
              organization.fein,
              organization.hbx_id,
              'Employer Profile',
              organization.employer_profile.contact_method]
    rescue => e
      puts "Employer Profile, Message: #{e.message}"
    end
    tt
  end

  ::BenefitSponsors::Organizations::Organization.broker_agency_profiles.inject([]) do |tt, organization|
    begin
      csv << [organization.legal_name,
              organization.fein,
              organization.hbx_id,
              'Broker Agency Profile',
              organization.broker_agency_profile.contact_method]
    rescue => e
      puts "Broker Agency Profile, Message: #{e.message}"
    end
    tt
  end

  ::BenefitSponsors::Organizations::Organization.general_agency_profiles.inject([]) do |tt, organization|
    begin
      csv << [organization.legal_name,
              organization.fein,
              organization.hbx_id,
              'General Agency Profile',
              organization.general_agency_profile.contact_method]
    rescue => e
      puts "General Agency Profile, Message: #{e.message}"
    end
    tt
  end
end
puts "End of rake, time: #{Time.zone.now}"
