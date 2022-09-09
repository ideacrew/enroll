# RAILS_ENV=production bundle exec rake migrations:term_cancel_enrollment
# Rake task to terminate or cancel an existing HBX Enrollment
# Interactive rake that takes input from the user to be completed

require File.join(Rails.root, "app", "data_migrations","rake", "term_cancel_enrollment")

namespace :migrations do
  desc "Terminate or Cancel HBX Enrollment"
  TermCancelEnrollment.define_task :term_cancel_enrollment => :environment
end
