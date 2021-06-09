# frozen_string_literal: true

# Class to create Golden Seed records from CSV
class SeedRowWorker
  include Sidekiq::Worker
  include CableReady::Broadcaster

  def perform(_row_id, _seed_id)
    sleep 2
    # Tons of stuff
  end
end