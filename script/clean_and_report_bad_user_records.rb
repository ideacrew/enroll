require 'csv'
csv_file_path = "iam.csv"
mismatch_count = 0
oim_update_count = 0

oim_mismatch_report = File.open("oim_mismatch_report.txt", "w")
oim_blank_report = File.open("oim_blank_report.txt", "w")
blank_oim_and_invalid_users = File.open("oim_blank_and_invalid_users.txt", "w")

CSV.foreach(csv_file_path, headers: true) do |row|
  users = row.to_hash
  iam_email = users["IAM_EMAIL"]
  iam_username = users["IAM_USERNAME"]     # Synonymous to oim_id in the Person record.
  user = User.where(email:iam_email).first if iam_email.present?

  next if (user.blank? || user.email.blank?)
  
  if user.oim_id.present?
    if user.oim_id.downcase !=  iam_username.downcase
      oim_mismatch_report.puts "OIM ID MISMATCH for [ #{user.email} ]   -  CSV says: #{iam_username} BUT DB says: #{user.oim_id}"
      mismatch_count += 1
    end
  else
    # If user record is missing oim_id, populate it from the CSV
    begin
      user.update_attributes!(oim_id: iam_username)
      oim_blank_report.puts "OIM ID IS BLANK for [ #{user.email} ]  -  Updated with the OIM ID (#{iam_username}) from the CSV file."
      oim_update_count += 1
    rescue Exception => e
      blank_oim_and_invalid_users.puts "CANT UPDATE USER record with OIM ID for [ #{user.email} ]. user.update_attributes FAILED! ERROR : #{user.errors.messages}, Exception thrown: #{e.message} "
    end 
  end
end  
oim_mismatch_report.puts  "TOTAL COUNT OF OIM ID MISMATCH (CSV vs DB): #{mismatch_count}"
oim_blank_report.puts     "TOTAL COUNT OF OIM ID UPDATES (In case where user records were missing the oim_id in DB) (CSV to DB):  #{oim_update_count}"
oim_mismatch_report.close
oim_blank_report.close


users = User.where(oim_id: nil)
users.no_timeout.each do |user|
   blank_oim_and_invalid_users.puts "OIM ID BLANK and PERSON RECORD PRESENT for [ #{user.email} ]" if user.try(:person).present?
end

User.all.no_timeout.each do |user|
  begin
    if !user.valid?
      blank_oim_and_invalid_users.puts "INVALID USER [ #{user.email} ]. Object not valid. ERROR: #{user.errors.messages}" 
    end
  rescue Exception => e
      puts "EXCEPTION THROWN (when doing user.valid?) [ #{user.email} ] : #{e}"
  end
end

blank_oim_and_invalid_users.close