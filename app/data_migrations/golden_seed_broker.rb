# frozen_string_literal: true

require File.join(Rails.root, 'lib/mongoid_migration_task')
require File.join(Rails.root, 'app/data_migrations/golden_seed_helper')


# This class will create a broker that can be used locally
# Will be signed up for both IVL and SHOP markets
# No employers assigned yet since we don't have Golden Seed code for that
class GoldenSeedIndividual < MongoidMigrationTask
  include GoldenSeedHelper

  def migrate

  end


end