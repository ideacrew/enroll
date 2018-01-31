namespace :shop do
  desc "Print out employer pending POCs"
  task :employer_poc_pending_report => :environment do
    roles = Person.where(:employer_staff_roles.exists => true).map(&:employer_staff_roles).flatten
    pending = roles.select{|role| role.aasm_state == 'is_applicant'}
    time_stamp = Time.now.strftime("%Y%m%d_%H%M%S")
    file_name = File.expand_path("#{Rails.root}/public/er_poc_pending_app_report_#{time_stamp}.csv")

    CSV.open(file_name, "w", force_quotes: true) do |csv|
      csv << ['ER POC Applicant Name','ER POC Email Address','ER Legal Name','ER FEIN','ER POC Application Date Time']
      pending.each do |role|
        org = EmployerProfile.find(role.employer_profile_id).organization
        csv << [role.person.full_name, role.person.work_email_or_best, org.legal_name, org.fein, role.updated_at.to_s]
      end
    end
    pubber = Publishers::Legacy::EmployerPocPendingReportPublisher.new
    pubber.publish URI.join("file://", file_name)
  end
end
