# frozen_string_literal: true

# Class to create Golden Seed records from CSV
class SeedWorker
  include Sidekiq::Worker
  include CableReady::Broadcaster
  include GoldenSeedWorkerConcern

  attr_accessor :target_seed

  def perform(seed_id)
    sleep 2
    # Tons of stuff
    @target_seed = ::Seeds::Seed.find(seed_id)
    # need to do the primary_person first
    target_seed.rows.order_by(:created_at.asc).each do |row|
      Rails.logger.warn("No data provided for Seed Row #{row.id} of seed #{target_seed.id}") if row.data.blank?
      next if row.data.blank?
      process_row(row.data, seed_id, row.id)
      html = ApplicationController.render(
        partial: "exchanges/seeds/row",
        locals: { row: @target_row }
      )

      cable_ready["seed-row-processing"].morph(
        selector: "#seed-#{seed_id}-row-#{row_id}",
        html: html
      )

      cable_ready.broadcast
    end
  end
end