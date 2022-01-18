# frozen_string_literal: true

require File.join(Rails.root, 'app', 'data_migrations', 'migrate_evidences')
# This rake task is to delete duplicate addresses for a given person
# RAILS_ENV=production bundle exec rake migrations:migrate_evidences

namespace :migrations do
  desc 'migrate evidences to new model'
  MigrateEvidences.define_task :migrate_evidences => :environment
end
