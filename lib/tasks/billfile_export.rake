require 'csv'

namespace :billfile do
  desc 'Create a BillFile for Wells Fargo.'
  # Usage rake billfile:from_file_path
  task :export => [:environment] do

    TITLE = "maconnector_#{DateTime.now.strftime('%Y%m%d_%H%M%S')}.csv"
    FILE_PATH = Rails.root.join TITLE

    CSV.open(FILE_PATH, 'w') do |csv|
      headers = ['Reference Number', 'Other Data', 'Company Name', 'Due Date', 'Amount Due']
      csv << headers

      BenefitSponsors::Organizations::Organization.employer_profiles.each do |org|
        begin
          benefit_sponsorship = org.active_benefit_sponsorship
          benefit_sponsorship_account = benefit_sponsorship.benefit_sponsorship_account
          if benefit_sponsorship && benefit_sponsorship_account
            current_statement_date = benefit_sponsorship_account.current_statement_date
            sponsored_due_date = current_statement_date.beginning_of_month + 22.days
            due_date = current_statement_date.present? ? format_due_date(sponsored_due_date) : nil
            # due_date = pull_due_date(benefit_sponsorship_account)
            total_due = format_total_due(benefit_sponsorship_account.total_due)
            row = []
            row += [org.hbx_id, org.fein, org.legal_name.gsub(',',''), due_date, total_due]
            csv << row if row.present?
          end
        rescue StandardError => e
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
      BenefitSponsors::BenefitSponsorships::BillFile.create(urn: uri, creation_date: Date.today, name: TITLE)
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
    format_due_date(account.current_statement_activities.where(:posting_date.gt => current_statement_date).sort_by(&:coverage_month).last.coverage_month.end_of_month)
  end
end
