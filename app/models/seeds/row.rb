# frozen_string_lateral: true

module Seeds
  class Row
    include Mongoid::Document
    include Mongoid::Timestamps
    
    embedded_in :seed, class_name: "Seeds::Seed"
    
    field :data, type: Hash
    field :record_id, type: String, default: ""
    # Primary Person
    field :record_class_name, type: String, default: ""
    
    def seeded?
      record_id.present?
    end
  end
end
