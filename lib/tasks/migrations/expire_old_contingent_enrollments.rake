require File.join(Rails.root, "app", "data_migrations", "expire_old_contingent_enrollments")
# This rake task is to migrate hbx_enrollments to get rid of enrolled_contingent state
# RAILS_ENV=production bundle exec rake migrations:expire_old_contingent_enrollments

namespace :migrations do
  desc "expire_old_contingent_enrollments"
  ExpireOldContingentEnrollments.define_task :expire_old_contingent_enrollments => :environment
end
