require File.join(Rails.root, "app", "data_migrations", "financial_assistance", "change_application_state")
# This rake task is to change the state of an application
# RAILS_ENV=production bundle exec rake migrations:change_application_state hbx_id=640826 action="terminate"
#For mutliple feins
# RAILS_ENV=production bundle exec rake migrations:change_application_state hbx_id=640826,640826,640826 action="terminate"
# RAILS_ENV=production bundle exec rake migrations:change_application_state hbx_id=640826,640826,640826 action="cancel"

namespace :migrations do
  desc "changing state of application"
  ChangeApplicationState.define_task :change_application_state => :environment
end
