require File.join(Rails.root, "app", "data_migrations", "change_office_phone_number")
# This rake task is to change the organization's primary office location's phone number
# RAILS_ENV=production bundle exec rake migrations:change_office_phone_number fein=123123123 full_phone_number="2122023123" country_code=""
namespace :migrations do
  desc "change office_phone_number"
  ChangeOfficePhoneNumber.define_task :change_office_phone_number => :environment
end