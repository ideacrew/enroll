# frozen_string_literal: true

# Class to create Golden Seed records from CSV
class SeedRowWorker
  include Sidekiq::Worker
  include CableReady::Broadcaster
  include GoldenSeedWorkerConcern

  attr_accessor :target_seed, :target_row

  def perform(row_id, seed_id)
    sleep 2
    # Tons of stuff
    @target_seed = ::Seeds::Seed.find(seed_id)
    @target_row = target_seed.rows.find(row_id)
    row_data = target_row.data
    Rails.logger.warn("No data provided for Seed Row #{target_row.id} of seed #{target_seed.id}") if row_data.blank?
    return if row_data.blank?
    process_row(row_data)
  end
end