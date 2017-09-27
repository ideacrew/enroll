namespace :families do
  desc "update vlp document status"
  task :update_vlp_documents_status => :environment do 
   Family.update_vlp_documents_status
  puts "All families are updated with vlp document status"
  end
end