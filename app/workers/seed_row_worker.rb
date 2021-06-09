# frozen_string_literal: true

# Class to create Golden Seed records from CSV 
class SeedRowWorker
  include Sidekiq::Worker
  include CableReady::Broadcaster

  def perform(row_id, seed_id)
    sleep 2
    # Tons of stuff
  end
end