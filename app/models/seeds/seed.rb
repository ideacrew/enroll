# frozen_string_lateral: true

module Seeds
  class Seed
    include Mongoid::Document
    include Mongoid::Timestamps
    include AASM
    
    embeds_many :rows, class_name: "Seeds::Row"

    belongs_to :user, class_name: "User"
    field :aasm_state, type: String
    field :filename, type: String

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
      row_ids = rows.map(&:id)
      row_ids.map do |row_id|
        SeedRowWorker.perform_async(row_id, self.id)
      end
      complete!
      save
    end
  end
end
