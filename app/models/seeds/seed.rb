# frozen_string_lateral: true

module Seeds
  class Seed
    include Mongoid::Document
    include Mongoid::Timestamps
    
    embeds_many :rows, class_name: "Seeds::Row"

    belongs_to :user, class_name: "User"

    field :filename, type: String
  end
end
