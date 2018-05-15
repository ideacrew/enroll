# Report: Rake task to find users account which has email address and no oim_id
require 'csv'

namespace :report do
  namespace :user_account do
    desc "List of users with no oim_id"
    task :with_no_oim_id => :environment do
      users = User.where(:"oim_id".exists=>false, :"email".exists=>true)
      field_names  = %w(
               user_id
               person_hbx_id
             )
      processed_count = 0
      Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
      file_name = "#{Rails.root}/hbx_report/users_account_with_no_oim_id.csv"
      CSV.open(file_name, "w", force_quotes: true) do |csv|
        csv << field_names
        users.each do |user|
            csv << [
                user.id,
                user.person.nil? ? " " : user.person.hbx_id
            ]
            processed_count += 1
        end
        puts "Total users with no oim_id in user account count #{processed_count} and users account output file: #{file_name}" unless Rails.env == 'test'
      end
    end
  end
end
