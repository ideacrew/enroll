require 'csv'

orgs = Organization.where(:'employer_profile'.exists => true)

CSV.open("poc_report.csv", "w") do |csv|
  csv << ["Legal Name", "Employer Hbx_id", "FEIN", "POC Name", "POC Phone", "POC Email"]

  orgs.each do |org|
    begin
      staff_roles = org.employer_profile.staff_roles
      if staff_roles.present?
        poc = staff_roles.each do |poc|
          poc_phone = poc.phones.detect{|phone| phone.kind = "work"}.full_phone_number rescue 'N/A'
          email_address = poc.emails.detect{|email| email.kind = "work"}.address rescue 'N/A'
          csv << [org.legal_name, org.hbx_id, org.fein, poc.full_name, poc_phone, email_address]
        end
      else
        csv << [org.legal_name, org.hbx_id, org.fein]
        puts "no poc for #{org.legal_name}"
      end
    rescue => e
      puts "ERROR: #{e.backtrace}"
    end
  end
end