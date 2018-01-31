require File.join(Rails.root, "app", "data_migrations", "change_enrollment_details")
# This rake task is to change the attributes on enrollment
# RAILS_ENV=production bundle exec rake migrations:change_enrollment_details hbx_id=609082 action="revert_enrollment"
# RAILS_ENV=production bundle exec rake migrations:change_enrollment_details hbx_id=609082 action="expire_enrollment"

#For mutliple feins
# RAILS_ENV=production bundle exec rake migrations:change_enrollment_details hbx_id=640826,640826,640826 action="expire_enrollment"

namespace :migrations do
  desc "changing attributes on enrollment"
  ChangeEnrollmentDetails.define_task :change_enrollment_details => :environment
end
