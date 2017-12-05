namespace :nfp do
  desc "Upload invoice to and associate with employer"
  task :invoice_upload => :environment do |task, args|
    invoice_folder = "invoices"
    current_month_folder = TimeKeeper.date_of_record.strftime("%b-%Y")
    if Rails.env.test?
      absolute_folder_path = File.expand_path("spec/test_data/invoices/#{current_month_folder}")
    else
      absolute_folder_path = File.expand_path("#{invoice_folder}/#{current_month_folder}")
    end
    if Dir.exists?(absolute_folder_path)
      Dir.entries(absolute_folder_path).each do |file|
        next if File.directory?(file) #skipping directories
        puts "uploading file #{absolute_folder_path}/#{file}"
        file_join_path = File.join(absolute_folder_path, file)
        # It will upload file to s3
        Organization.upload_invoice(file_join_path,file)
        # It will fetch organization
        organization = Organization.by_invoice_filename(file_join_path)
        # It will trigger notice
        trigger_notice_for_employer(organization) if organization.present?

      end
    else
      puts "Folder #{absolute_folder_path} doesn't exist. Please check and rerun the rake"
    end
  end

  def trigger_notice_for_employer(org)
    observer = Observers::Observer.new
    plan_year = org.employer_profile.active_plan_year
    observer.trigger_notice(recipient: org.employer_profile, event_object: plan_year, notice_event: "employer_invoice_available") if plan_year.present?
  end
end
