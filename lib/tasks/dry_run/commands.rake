namespace :dry_run do
  namespace :commands do
    desc "begin open enrollment for a given year"
    task :open_enrollment, [:year] => :environment do |t, args|
      # Close current year open enrollment
      system "RAILS_ENV=#{Rails.env} bundle exec rake migrations:update_ivl_open_enrollment_dates title='Individual Market Benefits #{args[:year].pred}' new_oe_end_date='#{(Date.yesterday - 2).to_s}'"
      # Open next year open enrollment
      system "RAILS_ENV=#{Rails.env} bundle exec rake migrations:update_ivl_open_enrollment_dates title='Individual Market Benefits #{args[:year]}' new_oe_start_date='#{Date.yesterday.to_s}'"
    end
  end

  desc "run the renewal process for a given year"
  task :renew, [:year] => :environment do |_t, args|
    FinancialAssistance::Operations::Applications::AptcCsrCreditEligibilities::Renewals::RequestAll.new.call({ renewal_year: args[:year] })
  end

  desc "run the determination process for a given year"
  task :determine, [:year] => :environment do |_t, args|
    FinancialAssistance::Operations::Applications::AptcCsrCreditEligibilities::Renewals::DetermineAll.new.call({ renewal_year: args[:year] })
  end

  desc "run the notice triggers for a given year"
  task :notify, [:year] => :environment do |_t, args|
    system "bundle exec rails runner script/oeg_oeq_notice_triggers.rb -e #{Rails.env}"
  end
end
