# This rake task is to update census dependent's ssn
# bundle exec rake migrations:update_ee_dependent_ssn ce_id=58dc0ced7a3672d66c0000bc dep_id=58dbd34c7a36725614000130 dep_ssn='nil'
# RAILS_ENV=production bundle exec rake migrations:update_ee_dependent_ssn ce_id=57e298a7faca147b43000645 dep_id=57e298a7faca147b43000645 dep_ssn='nil'

require File.join(Rails.root, "app", "data_migrations", "update_ee_dependent_ssn")
namespace :migrations do
  desc "update employee dependent ssn"
  UpdateEeDependentSSN.define_task :update_ee_dependent_ssn => :environment
end
