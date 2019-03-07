require File.join(Rails.root, "app", "data_migrations", "update_special_enrollment_period")
#RAILS_ENV=production bundle exec rake migrations:update_special_enrollment_period sep_id="5b523ba650526c15b700003b" attrs={market_kind:"shop"}

namespace :migrations do
  desc "Update special enrollments" 
  UpdateSpecialEnrollmentPeriod.define_task :update_special_enrollment_period => :environment
end
