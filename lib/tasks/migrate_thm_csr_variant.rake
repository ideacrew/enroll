# Rake task to interchange
# To run rake task: RAILS_ENV=production bundle exec rake migrations:migrate_csr_variant

require File.join(Rails.root, "app", "data_migrations", "migrate_thm_csr_variant")
namespace :migrations do
  desc "migrate_thm_csr_variant"
  MigrateThmCsrVariant.define_task :migrate_thm_csr_variant => :environment
end