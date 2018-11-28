require File.join(Rails.root, "app", "data_migrations", "update_writing_agent_id")
# RAILS_ENV=production bundle exec rake migrations:update_write_agent_id person_hbx_id="19843258" valid_writing_agent_id='561bf304547265b2365e1300'

namespace :migrations do
  desc "updating broker agency account and profile"
  UpdateWritingAgentId.define_task :update_writing_agent_id => :environment
end