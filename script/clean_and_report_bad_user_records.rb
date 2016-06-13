require 'csv'
csv_file = "/var/www/deployments/enroll/shared/iam.csv"
mismatch_count = 0
blank_count = 0

oim_mismatch_report = File.open("oim_mismatch_report.txt", "w")
oim_blank_report = File.open("oim_blank_report.txt", "w")
blank_oim_and_invalid_users = File.open("oim_blank_and_invalid_users.txt", "w")

CSV.foreach(csv_file, headers: true) do |row|
  users = row.to_hash
  iam_email = users["IAM_EMAIL"]
  iam_username = users["IAM_USERNAME"]     # Synonymous to oim_id in the Person record.
  user = User.where(email:iam_email).first
  next if user.blank?
  if user.oim_id.present?
    if user.oim_id.downcase !=  iam_username.downcase
      oim_mismatch_report.puts "OIM ID MISMATCH [ #{user.email} ]   -  CSV says: #{iam_username} BUT DB says: #{user.oim_id}"
      mismatch_count += 1
    end
  else
    # If user record is missing oim_id, populate it from the CSV
    user.update_attributes!(oim_id: iam_username)
    oim_blank_report.puts "OIM ID IS BLANK [ #{user.email} ]  -  Updated with the OIM ID from the CSV file."
    blank_count += 1
  end
end
  
oim_mismatch_report.puts  "TOTAL MISMATCH COUNT: #{mismatch_count}"
oim_blank_report.puts     "TOTAL BLANK COUNT:    #{blank_count}"



blank_oim_and_invalid_users.puts "****** Any OIM ID nil but Person record Present?\n"

users = User.where(oim_id: nil)
users.each do |user|
   blank_oim_and_invalid_users.puts "OIM ID BLANK and PERSON RECORD PRESENT [ #{user.email} ]" if user.try(:person).present?
end

blank_oim_and_invalid_users.puts "\n****** Any Invalid Users?"

User.all.no_timeout.each do |user|
  blank_oim_and_invalid_users.puts "INVALID USER [ #{user.email} ]. Object not valid" if !user.valid?
end