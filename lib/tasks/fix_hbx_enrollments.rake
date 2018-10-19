require File.join(Rails.root, "app", "data_migrations", "fix_hbx_enrollments")

namespace :migrations do
  desc "Fix enrollments for ivl market"
  FixHbxEnrollments.define_task :fix_hbx_enrollments => :environment
end