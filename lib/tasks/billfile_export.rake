require 'csv'

namespace :billfile do
  desc "Create a BillFile for Wells Fargo."
  # Usage rake billfile:from_file_path
  task :export => [:environment] do

    TITLE = "DCHEALTHPAY.#{DateTime.now.strftime('%Y%m%d.%H%M%S')}.csv"
    FILE_PATH = Rails.root.join TITLE

    CSV.open(FILE_PATH, "w") do |csv|
      headers = ["Reference Number", "Other Data", "Company Name", "Due Date", "Amount Due"]
      csv << headers

      Organization.all_employer_profiles.each do |org|
        begin
          employer_profile = org.employer_profile
          employer_profile_account = employer_profile.employer_profile_account
          if employer_profile && employer_profile_account
            due_date = format_due_date(employer_profile_account.current_statement_date.end_of_month)
            # due_date = pull_due_date(employer_profile_account)
            total_due = format_total_due(employer_profile_account.total_due)
            row = []

            row += [org.hbx_id, org.fein, org.legal_name.gsub(',',''), due_date, total_due]
            if row.present?
              csv << row
            end
          end
        rescue Exception => e
          puts "Unable to pull account information for #{org.legal_name} due to #{e}"
        end
      end #Closes orgs
      puts "Saved to #{FILE_PATH}"
    end #Closes CSV
    upload_and_save_reference
  end

  # keeps value two decimal places from right
  def format_total_due(total_due)
    ("%.2f" % total_due)
  end

  def upload_and_save_reference
    uri = upload_to_amazon
    if uri.present?
      BillFile.create(urn: uri, creation_date: Date.today, name: TITLE)
    else
      raise "No file present to save to S3."
    end
  end

  def upload_to_amazon
    begin
      Aws::S3Storage.save(FILE_PATH, 'billfile')
    rescue Exception => e
      raise "unable to upload to Amazon S3 due to #{e}"
    end
  end

  def format_due_date(date)
    date.try(:strftime, '%m/%d/%Y')
  end

  def delete_bill_file
    File.delete(FILE_PATH)
  end

  def pull_due_date(account)
    current_statement_date = account.current_statement_date
    format_due_date(account.current_statement_activity.where(:posting_date.gt => current_statement_date).sort_by(&:coverage_month).last.coverage_month.end_of_month)
  end
end
