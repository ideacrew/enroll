# frozen_string_literal: true

require File.join(Rails.root, "app", "data_migrations", "products", "mark_products_as_hc4cc_eligible")
# This rake task is to update proudcts as hc4cc eligible
# RAILS_ENV=production bundle exec rake migrations:mark_products_as_hc4cc_eligible file_name="test.csv"

namespace :migrations do
  desc "add plans to list of OSSE plans by marking them as hc4cc plan"
  MarkProductsAsHc4ccEligible.define_task :mark_products_as_hc4cc_eligible => :environment
end