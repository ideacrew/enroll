# frozen_string_literal: true

require File.join(Rails.root, 'app', 'data_migrations', 'build_family_determinations')
# This rake task is to build families determinations
# RAILS_ENV=production bundle exec rake migrations:build_family_determinations

namespace :migrations do
  desc 'build families determinations'
  BuildFamilyDeterminations.define_task :build_family_determinations => :environment
end
