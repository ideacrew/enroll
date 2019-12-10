# frozen_string_literal: true

require File.join(Rails.root, 'app', 'data_migrations', 'delete_duplicate_addresses')
# This rake task is to delete duplicate addresses for a given person
# RAILS_ENV=production bundle exec rake migrations:delete_duplicate_addresses  person_hbx_id='123123123'

namespace :migrations do
  desc 'delete duplicate addresses'
  DeleteDuplicateAddresses.define_task :delete_duplicate_addresses => :environment
end
