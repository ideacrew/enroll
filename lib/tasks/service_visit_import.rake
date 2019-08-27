require File.join(Rails.root, "app", "data_migrations", "service_visit_import")
# This rake task is to import service visits
# RAILS_ENV=production bundle exec rake migrations:service_visit_import
namespace :migrations do
  desc "import service visits"
  ServiceVisitImport.define_task :service_visit_import => :environment
end 