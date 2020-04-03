# frozen_string_literal: true

require File.join(Rails.root, 'app', 'data_migrations', 'delete_duplicate_tax_households')
# This rake task is to delete duplicate tax households for a given person
# RAILS_ENV=production bundle exec rake migrations:delete_duplicate_tax_households person_hbx_id='123123123'

namespace :migrations do
  desc 'delete duplicate tax households'
  DeleteDuplicateTaxHouseholds.define_task :delete_duplicate_tax_households => :environment
end
