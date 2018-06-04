require File.join(Rails.root, "lib/mongoid_migration_task")

class MigrateInvoicesToEmployerProfile < MongoidMigrationTask
  def migrate
    
    Organization.all_employer_profiles.each do |org|
      begin
        invoices = org.documents.select{ |invoice| invoice.subject == "invoice" }
        next if invoices.empty?
        puts "Found #{invoices.count} invoices for employer #{org.fein}"
        invoices.each do |invoice|
          org.employer_profile.documents << invoice
        end
        org.save!
        org.reload
        org.documents.select{ |invoice| (invoice.subject == "invoice") && (org.employer_profile.documents.include?(invoice)) }.each{|doc| doc.delete}
        puts "Successfully migrated invoices from Organization to employer_profile for FEIN: #{org.fein}"
      rescue Exception => e
        log("#{e.message}; for employer with FEIN: #{org.fein}")
      end
    end
  end
end
