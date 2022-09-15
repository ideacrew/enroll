# frozen_string_literal: true

require File.join(Rails.root, "app", "data_migrations", "update_expected_contribution_for_2022_active_determinations")
# This rake task is to update expected contribution for 2022 active determinations
# RAILS_ENV=production bundle exec rake migrations:update_expected_contribution_for_2022_active_determinations

namespace :migrations do
  desc 'updates expected contribution for 2022 active determinations'
  UpdateExpectedContributionFor2022ActiveDeterminations.define_task :update_expected_contribution_for_2022_active_determinations => :environment
end
