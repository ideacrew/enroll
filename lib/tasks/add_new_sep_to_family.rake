# frozen_string_literal: true

require File.join(Rails.root, "app", "data_migrations", "add_new_sep_to_family")
# This rake task is to build shop enrollment
# RAILS_ENV=production bundle exec rake migrations:add_new_sep_to_family sep_type='ivl' qle_reason='open_enrollment_december_deadline_grace_period'
  # event_date='12/28/2021' sep_duration='10' person_hbx_ids="123456789 987654321"

namespace :migrations do
  desc "creating a new shop enrollment"
  AddNewSepToFamily.define_task :add_new_sep_to_family => :environment
end 
