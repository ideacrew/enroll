# Rake task used to update plan year field announced_externally to true for valid plan year.
# To run rake task: RAILS_ENV=production bundle exec rake migrations:update_py_announced_externally_flag

require File.join(Rails.root, "app", "data_migrations", "update_py_announced_externally_flag")
namespace :migrations do
  desc "update_benefit_group_id"
  UpdatePyAnnouncedExternallyFlag.define_task :update_py_announced_externally_flag => :environment
end