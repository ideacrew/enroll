namespace :families do
  desc "update vlp document status"
  task :update_vlp_documents_status => :environment do 
   Family.each do |f|
      f.update_attributes(vlp_documents_status: f.primary_applicant.person.vlp_documents_status) if f.primary_applicant.person.consumer_role
   end
  puts "All families are updated with vlp document status"
  end
end