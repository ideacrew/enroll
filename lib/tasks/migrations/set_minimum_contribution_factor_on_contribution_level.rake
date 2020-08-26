# frozen_string_literal: true

require File.join(Rails.root, "app", "data_migrations", "set_minimum_contribution_factor_on_contribution_level")
# This rake task updates assigned contribution model on contribution models(benefit sponsor catalog's)
# RAILS_ENV=production bundle exec rake migrations:set_minimum_contribution_factor_on_contribution_level
namespace :migrations do
  desc "set minimum contribution factor on contribution levels"
  SetMinimumContributionFactorOnContributionLevel.define_task :set_minimum_contribution_factor_on_contribution_level => :environment
end

