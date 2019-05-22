require File.join(Rails.root, "app", "data_migrations", "correct_due_date_affected_by_FEL_notice")
# This rake task is to correct due date affected by FEL notice 
# RAILS_ENV=production bundle exec rake migrations:correct_due_date_affected_by_FEL_notice
namespace :migrations do
  desc "correct_due_date_affected_by_FEL_notice"
  CorrectDueDateAffectedByFELNotice.define_task :correct_due_date_affected_by_FEL_notice => :environment
end
