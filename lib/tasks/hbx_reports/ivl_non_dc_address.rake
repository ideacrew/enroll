# Monthly Report: Rake task to find IVL cases with active coverage with non-DC addresses
# Run this task every Month: RAILS_ENV=production bundle exec rake reports:ivl:ivl_non_dc_address

require 'csv'
 
namespace :reports do
  namespace :ivl do

    desc "Monthly report of IVL cases with non-DC addresses"
    task :ivl_non_dc_address, [:file] => :environment do

      field_names  = %w(
        hbx_id 
        full_name 
        ssn 
        dob 
        address 
        no_dc_address_reason 
        consumer_role 
        employee_role
      )
      processed_count = 0
      family_member_count = 0
      Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
      file_path = "#{Rails.root}/hbx_report/ivl_non_dc_address.csv"
      CSV.open(file_path, "w", force_quotes: true) do |csv|
        csv << field_names

        Person.where(no_dc_address: true).each do |person|
          begin
            if person.primary_family.present? && person.primary_family.active_household.hbx_enrollments.where(:aasm_state.in => HbxEnrollment::ENROLLED_STATUSES).present?
              csv << [person.hbx_id, 
                      person.full_name, 
                      person.ssn, 
                      person.dob, 
                      person.contact_addresses.try(:first).try(:full_address), 
                      person.no_dc_address_reason, 
                      person.consumer_role.present?, 
                      person.employee_roles.present?
                     ]
              processed_count +=1
            end
          rescue Exception => e
            puts e.message
          end
          family_member_count +=1
        end
        puts "File path: %s. Total count of IVL cases with non DC address: %d. Total count including dependents: %d" %[file_path, processed_count, family_member_count]
      end
    end
  end
end