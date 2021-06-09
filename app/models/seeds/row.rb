# frozen_string_literal: true

module Seeds
  # Class used to hold data from CSVs to provide a template
  # for creating seed data
  class Row
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :seed, class_name: "Seeds::Seed"

    field :data, type: Hash
    field :record_id, type: String, default: ""
    # Primary Person
    # TODO: Could be other classes in the future
    # This will be used to reference the records it creates
    field :record_class_name, type: String, default: ""

    def seeded?
      record_id.present?
    end
  end
end
