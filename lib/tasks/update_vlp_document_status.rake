namespace :families do
  desc "update vlp document status"
  task :update_vlp_documents_status => :environment do

    family_count = Family.count
    offset_count = 0
    limit_count = 500
    processed_count = 0

    while (offset_count <= family_count) do

      puts "offset_count: #{offset_count}"

      Family.limit(limit_count).offset(offset_count).each do |fam|
        begin
          if fam.primary_applicant.present? && fam.primary_applicant.person.present? && fam.primary_applicant.person.consumer_role.present?
          	fam.update_family_document_status! 
          	processed_count += 1
          end	
        rescue => e
          puts "Failed to update vlp document status for family #{fam.inspect}" + e.message
        end
      end
      offset_count += limit_count
    end
    puts "Total families #{processed_count} are udpdated with vlp document status."
  end
end