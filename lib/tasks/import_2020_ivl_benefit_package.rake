require File.join(Rails.root, "app", "data_migrations", "import_2020_ivl_benefit_package")
# This rake task is to create benefit package for 2020
# RAILS_ENV=production bundle exec rake migrations:import_2020_ivl_benefit_package
namespace :migrations do
  desc "create 2020 IVL benefit package"
  Import2020IvlBenefitPackage.define_task :import_2020_ivl_benefit_package => :environment
end
