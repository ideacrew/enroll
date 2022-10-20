# frozen_string_literal: true

require File.join(Rails.root, "app", "data_migrations", "trigger_rrv_by_year")
# This rake task is to generate rrv files for the year
# RAILS_ENV=production bundle exec rake migrations:trigger_rrv_by_year assistance_year=2023

namespace :migrations do
  desc 'trigger rrv for the given year'
  TriggerRrvByYear.define_task :trigger_rrv_by_year => :environment
end
