# frozen_string_literal: true

# Class to create Golden Seed records from CSV
class SeedWorker
  include Sidekiq::Worker
  include CableReady::Broadcaster
  include GoldenSeedWorkerConcern

  attr_accessor :target_seed

  def perform(seed_id)
    puts("Beginning the seed ID perform.")
    sleep 2
    # Tons of stuff
    @target_seed = ::Seeds::Seed.find(seed_id)
    # need to do the primary_person first
    Rails.logger.warn("No CSV Template provided for Seed #{target_seed.id}") if target_seed.csv_template.blank?
    abort if target_seed.csv_template.blank?
    target_seed.rows.each do |row|
      Rails.logger.warn("No data provided for Seed Row #{row.id} of seed #{target_seed.id}") if row.data.blank?
      next if row.data.blank?
      process_row(row)
      row.reload
      html = ApplicationController.render(
        partial: "exchanges/seeds/row",
        locals: { row: row }
      )
      puts("Beginning row morph for row #{row.id}")

      cable_ready["seed-row-processing"].morph(
        selector: "#seed-#{seed_id}-row-#{row.id}",
        html: html
      )

      cable_ready.broadcast
    end
  end
end