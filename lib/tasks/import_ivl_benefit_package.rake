# frozen_string_literal: true

require File.join(Rails.root, "app", "data_migrations", "import_ivl_benefit_package")
# This rake task is to create benefit package for given year
# We need to pass `year` as an argument for which we want to create benefit package
# RAILS_ENV=production bundle exec rake migrations:import_ivl_benefit_package year=2021
namespace :migrations do
  desc "create IVL benefit package"
  ImportIvlBenefitPackage.define_task :import_ivl_benefit_package => :environment
end
