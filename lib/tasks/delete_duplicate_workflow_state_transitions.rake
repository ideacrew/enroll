# frozen_string_literal: true

require File.join(Rails.root, 'app', 'data_migrations', 'delete_duplicate_workflow_state_transitions')
# This rake task is to delete duplicate workflow state transitions for a given person
# RAILS_ENV=production bundle exec rake migrations:delete_duplicate_workflow_state_transitions person_hbx_id='123123123'

namespace :migrations do
  desc 'delete duplicate workflow state transitions'
  DeleteDuplicateWorkflowStateTransitions.define_task :delete_duplicate_workflow_state_transitions => :environment
end
