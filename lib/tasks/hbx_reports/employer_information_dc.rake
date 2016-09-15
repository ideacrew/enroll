require 'csv'

namespace :reports do
  namespace :shop do

    desc "Identify employer's account information"
    task :employer_information_dc => :environment do
    
      # collect active organizations
      organizations = Organization.where(:'employer_profile'.exists=>true )

      field_names  = %w(
          employer_HBX_ID
          employer_DBA
          employer_FEIN
          B_CONTACT_PREFIX
          B_CONTACT_FNAME
          B_CONTACT_MI
          B_CONTACT_LNAME
          B_CONTACT_SUFFIX
          B_address_kind
          B_ADD1
          B_ADD2
          B_address_3
          B_CITY
          B_STATE
          B_ZIP
          B_PHONE
          B_EMAIL
          M_CONTACT_PREFIX
          M_CONTACT_FNAME
          M_CONTACT_MI
          M_CONTACT_LNAME
          M_CONTACT_SUFFIX
          M_address_kind
          M_ADD1
          M_ADD2
          M_address_3
          M_CITY
          M_STATE
          M_ZIP
          M_PHONE
          M_EMAIL
        )
      processed_count = 0

      Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
      file_name = "#{Rails.root}/hbx_report/employer_information_dc.csv"

      CSV.open(file_name, "w", force_quotes: true) do |csv|
        csv << field_names
        # for each active organiztaions
        organizations.each do |organization|

              poc = Person.where(:'employer_staff_roles.employer_profile_id' =>organization.employer_profile.id,:"employer_staff_roles.is_active" => true).first
              billing = organization.primary_office_location.address
              # phone = organization.primary_office_location.phone
              csv << [
                  organization.hbx_id,
                  organization.dba,
                  organization.fein,
                  poc.try(:name_pfx),
                  poc.try(:first_name),
                  poc.try(:middle_name),
                  poc.try(:last_name),
                  poc.try(:name_sfx),
                  billing.try(:address_kind),
                  billing.try(:address_1),
                  billing.try(:address_2),
                  billing.try(:address_3),
                  billing.try(:city),
                  billing.try(:state),
                  billing.try(:zip),
                  organization.try(:primary_office_location).try(:phone).try(:full_phone_number),
                  poc.try(:work_email).try(:address),
                  poc.try(:name_pfx),
                  poc.try(:first_name),
                  poc.try(:middle_name),
                  poc.try(:last_name),
                  poc.try(:name_sfx),
                  organization.try(:mailling_address) .try(:address).try(:address_kind),
                  organization.try(:mailling_address).try(:address).try(:address_1),
                  organization.try(:mailling_address).try(:address).try(:address_2),
                  organization.try(:mailling_address).try(:address_3),
                  organization.try(:mailling_address).try(:address).try(:city),
                  organization.try(:mailling_address).try(:address).try(:state),
                  organization.try(:mailling_address).try(:address).try(:zip),
                  organization.try(:mailling_address).try(:phone).try(:full_phone_number),
                  poc.try(:work_email).try(:address),
             
              ]
            end
            processed_count += 1
          end
        end
      puts "Total List of Employers for discrepancy report "
    end
end