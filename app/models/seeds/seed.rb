# frozen_string_literal: true

require "#{Rails.root}/app/models/concerns/seeds/csv_headers.rb"
module Seeds
  # Provides rows which have rows from CSVs that have hashes
  # used to provide seed data.
  class Seed
    include Mongoid::Document
    include Mongoid::Timestamps
    include AASM
    include Seeds::CsvHeaders

    embeds_many :rows, class_name: "Seeds::Row"
    belongs_to :user, class_name: "User"

    field :aasm_state, type: String
    field :filename, type: String
    field :csv_template, type: String

    aasm do
      state :draft, initial: true
      state :processing, after_enter: :create_records!
      state :completed
      state :failure

      event :process do
        transitions from: :draft, to: :processing
      end

      event :complete do
        transitions from: :processing, to: :completed
      end
    end

    def create_records!
      puts("Beginning create records.")
      SeedWorker.perform_async(self.id)
      complete!
      save
    end
  end
end
