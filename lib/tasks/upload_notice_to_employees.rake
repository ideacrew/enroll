# Run the following - bundle exec rake migrations:upload_notice_to_employees input_file_name=upload_notice_to_employers
require 'csv'

namespace :migrations do
  desc "Adding notices to EE accounts"
  task :upload_notice_to_employees => :environment do

    input_file_name = ENV['input_file_name']
    CSV.foreach("#{Rails.root}/lib/#{input_file_name}.csv", headers: true) do |row|
      begin
        hbx_id = row["Subscriber HBX ID"]
        ENV['file_path'] = "lib/#{row['File Path']}"
        ENV['hbx_id'] = hbx_id
        ENV['notice_name'] = row["Notice Title"]
        Rake::Task["migrations:upload_notice_to_employee_account"].execute
        puts "Finished with EE with hbx_id - #{hbx_id}"
      rescue Exception => e
        puts "Errors with #{hbx_id} - #{e.backtrace}"
      end
    end
  end
end
