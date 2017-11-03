# Report to find all non_citizens and their immigration documents
# To run: RAILS_ENV=production bundle exec rake report:lawful_alien_documents
require 'csv'

namespace :report do
  desc "List of lawful aliens with their documents"
  task :lawful_alien_documents => :environment do 
    lawful_aliens = Person.where(:consumer_role => {"$exists" => true}, 
                                "consumer_role.lawful_presence_determination.citizen_status" => 
                                  {"$nin" => %w(us_citizen 
                                                indian_tribe_member 
                                                undocumented_immigrant 
                                                not_lawfully_present_in_us 
                                                non_native_not_lawfully_present_in_us)+[nil]})
    puts lawful_aliens.size
    field_names = ["Person HBX ID", "First Name", "Last Name", "DOB", "SSN", "Citizen Status", "Document(s)","Last Updated Date"]
    Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
    file_name = "#{Rails.root}/hbx_report/lawful_alien_documents_#{Time.now.strftime('%Y%m%d%H%M')}.csv"
    count = 0 
    CSV.open(file_name,"w") do |csv|
      csv << field_names
      lawful_aliens.each do |la|
        count += 1
        next if la.consumer_role.blank?
        next if la.primary_family.blank?
        next if la.primary_family.primary_applicant.person != la
        next if la.primary_family.active_household.blank?
        next if la.primary_family.active_household.hbx_enrollments.blank?
        active_hbx_enrollments = la.primary_family.active_household.hbx_enrollments.select{|hbx_en| (hbx_en.effective_on.year == 2017) && (HbxEnrollment::ENROLLED_STATUSES.include?(hbx_en.aasm_state))}
        next if active_hbx_enrollments.blank?
        hbx_id = la.hbx_id
        first_name = la.first_name
        last_name = la.last_name
        dob = la.dob
        ssn = la.ssn
        citizen_status = la.consumer_role.lawful_presence_determination.citizen_status
        if la.consumer_role.vlp_documents.size > 0
          la.consumer_role.vlp_documents.each do |i|
            if VlpDocument::VLP_DOCUMENT_KINDS.include? i.subject
              csv << [hbx_id, first_name, last_name, dob, ssn, citizen_status, i.subject, i.updated_at]
            end
          end
        elsif la.consumer_role.vlp_documents.size == 0
          documents = "No VLP Documents Found"
          update_date= ""
          csv << [hbx_id, first_name, last_name, dob, ssn, citizen_status, documents, update_date]
        end

      end
    end
  end
end

