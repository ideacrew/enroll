# frozen_string_literal: true

require File.join(Rails.root, "app", "data_migrations", "import_ivl_benefit_coverage_period")
# This rake task is to create benefit coverage period for given year
# We need to pass `year` as an argument for which we want to create benefit coverage period
# RAILS_ENV=production bundle exec rake migrations:import_ivl_benefit_coverage_period year=2021
namespace :migrations do
  desc "create IVL benefit coverage period"
  ImportIvlBenefitCoveragePeriod.define_task :import_ivl_benefit_coverage_period => :environment
end
