namespace :delete do
  desc "cache premiums plan for fast group fetch"
  task :minute_man_plans_2017 => :environment do
    puts "*"*80 unless Rails.env.test?
    puts "Remove minute man 2017 plans" unless Rails.env.test?
    Plan.where(active_year: 2017, carrier_profile_id: "53e67210eb899a4603000053").delete_all
    puts "Successfully removed minute man 2017 plans" unless Rails.env.test?
    puts "*"*80 unless Rails.env.test?
  end
end
