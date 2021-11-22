# frozen_string_literal: true

require File.join(Rails.root, "app", "data_migrations", "update_consumer_role_verification_status")
# This rake task is to change the aasm state on consumer_role and verification_status on enrollment
# RAILS_ENV=production bundle exec rake migrations: update_consumer_role_verification_status

namespace :migrations do
  desc "change ce date of termination"
  UpdateConsumerRoleVerificationStatus.define_task :update_consumer_role_verification_status => :environment
end
