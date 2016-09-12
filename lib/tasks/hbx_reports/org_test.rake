require 'csv'

namespace :reports do
  namespace :shop do

    desc "Identify employer's account information"
    task :org_test => :environment do
    
      # collect active organizations
      organizations = Organization.where(:'employer_profile'.exists=>true )

      field_names  = %w(
          employer_hbx_id
          employer_legal_name
          employer_fein
          M_address_kind
          M_address_1
          M_address_2
          M_address_3
          M_city
          M_state
          M_zip
          phone_kind
          poc_email
          poc_phone_number
        )
      processed_count = 0

      Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
      file_name = "#{Rails.root}/hbx_report/org_test.csv"

      CSV.open(file_name, "w", force_quotes: true) do |csv|
        csv << field_names
        # for each active organiztaions
        organizations.each do |organization|

              poc = Person.where(:'employer_staff_roles.employer_profile_id' =>organization.employer_profile.id,:"employer_staff_roles.is_active" => true).first
              add = organization.primary_office_location.address
              csv << [
                  organization.hbx_id,
                  organization.legal_name,
                  organization.fein,
                  add.try(:address_kind),
                  add.try(:address_1),
                  add.try(:address_2),
                  add.try(:address_3),
                  add.try(:city),
                  add.try(:state),
                  add.try(:zip),
                  poc.try(:phone_kind),
                  poc.try(:work_email).try(:address),
                  poc.try(:work_phone).try(:full_phone_number)
             
              ]
            end
            processed_count += 1
          end
        end
      puts "List of Employers"
    end
end