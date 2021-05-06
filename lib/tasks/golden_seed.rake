# frozen_string_literal: true

require File.join(Rails.root, "app", "data_migrations", "golden_seed_individual")

# RAILS_ENV=production bundle exec rake migrations:golden_seed_individual
namespace :migrations do
  desc "Generates consumers, families, and enrollments for them from existing carriers and plans. Can be run on any environment without affecting existing data. Uses existing carriers/plans."
  GoldenSeedIndividual.define_task :golden_seed_individual => :environment
end