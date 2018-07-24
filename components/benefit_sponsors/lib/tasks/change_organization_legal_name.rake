require File.join(Rails.root, "components", "benefit_sponsors", "app", "data_migrations", "change_organization_legal_name")
# This rake task is to change the legal name of a organization
# RAILS_ENV=production bundle exec rake migrations:change_organization_legal_name fein=333333333 new_legal_name="New Er3-Corp"

namespace :migrations do
  desc "change the legal name of an organization"
  ChangeOrganizationLegalName.define_task :change_organization_legal_name => :environment
end
