# Report: Rake task to find users account which has oim_id and no email address
# To Run Rake Task: RAILS_ENV=production rake report:user_account:with_no_email_address
require 'csv'

namespace :report do
  namespace :user_account do

    desc "List of users with no email address in user account"
    task :with_no_email_address => :environment do

      users = User.where(:"oim_id".exists=>true, :"email".exists=>false)
      field_names  = %w(
               username
               user_first_name
               user_last_name
               person_hbx_id
               person_home_email
               person_work_email
             )
      processed_count = 0
      Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
      file_name = "#{Rails.root}/hbx_report/users_account_with_no_email.csv"

      CSV.open(file_name, "w", force_quotes: true) do |csv|
        csv << field_names

        users.each do |user|
          if user.person.present?
            csv << [
                user.oim_id,
                user.person.first_name,
                user.person.last_name,
                user.person.hbx_id,
                user.person.try(:emails).where(kind: "home").try(:first).try(:address),
                user.person.try(:emails).where(kind: "work").try(:first).try(:address)
            ]
            processed_count += 1
          end
        end
        puts "Total users with no email address in user account count #{processed_count} and users account output file: #{file_name}"
      end
    end
  end
end