require 'csv'

namespace :billfile do
  desc "Create a BillFile for Wells Fargo."
  # Usage rake billfile:from_file_path
  task :export => [:environment] do
    orgs = Organization.all

    FILE_PATH = Rails.root.join "#{Time.now.strftime('%Y-%m-%d')}_BillFile.csv"
    Title = "#{Time.now.strftime('%Y-%m-%d')}_BillFile.csv"
    # keeps value two decimal places from right
    def format_total_due(total_due)
      ("%.2f" % total_due)
    end

    CSV.open(FILE_PATH, "w") do |csv|
      headers = ["Reference Number", "Other Data", "Company Name", "Due Date", "Amount Due"]
      csv << headers
  
      orgs.each do |org|
        reference_number = org.hbx_id
        secondary_auth = org.fein
        consolidated_legal_name = org.legal_name.gsub(',','')
        invoice = org.documents.order(date: :desc).limit(1).first
  
        if invoice.present?
          nfp = NfpIntegration::SoapServices::Nfp.new(reference_number)
          due_date = invoice.date.end_of_month.strftime("%m/%d/%Y")
          if nfp.present?
            total_due = format_total_due(nfp.statement_summary.xpath("//TotalDue").text)
          end
          row = []
          row += [reference_number, secondary_auth, consolidated_legal_name, due_date, total_due]
          if row.present?
            csv << row
          end
        end
      end #Closes orgs
      puts "Saved to #{FILE_PATH}"
    end #Closes CSV
  end
  
  task :save_to_s3 => [:environment] do
    bill_file = Aws::S3Storage.save(FILE_PATH, 'billfile')
    if bill_file.present?
      BillFile.create(urn: bill_file, creation_date: Date.today, name: Title)
    else
      raise "No file present to save to S3."
    end
  end
  
  task :from_file_path => [:environment] do
    File.delete(FILE_PATH)
  end
  
  #task :remove_from_s3 => [:environment] do
  #end
  
  Rake::Task[:from_file_path].enhance [:export, :save_to_s3]
end