# frozen_string_literal: true

require File.join(Rails.root, 'app', 'data_migrations', 'delete_nil_evidences')
# This rake task is to delete duplicate addresses for a given person
# RAILS_ENV=production bundle exec rake migrations:delete_nil_evidences

namespace :migrations do
  desc 'delete duplicate addresses'
  DeleteNilEvidences.define_task :delete_nil_evidences => :environment
end
