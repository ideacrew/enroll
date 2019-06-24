require File.join(Rails.root, "app", "data_migrations", "reset_due_dates_for_outstanding_consumers")
# RAILS_ENV=production bundle exec rake migrations:reset_due_dates_for_outstanding_consumers

namespace :migrations do
  desc "resetting due dates for outstanding consumers"
  ResetDueDatesForOutstandingConsumers.define_task :reset_due_dates_for_outstanding_consumers => :environment
end 