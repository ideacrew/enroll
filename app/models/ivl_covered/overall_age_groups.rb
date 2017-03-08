module IvlCovered
  class OverallAgeGroups
    include Mongoid::Document
    store_in collection: "ivlCovered"

    field :tile , type: String
    field :zero_count, type: Integer
    field :zero_share, type: String
    field :zero_yoy, type: String
    field :one_count, type: Integer
    field :one_share, type: String
    field :one_yoy, type: String
    field :eighteen_count, type: Integer
    field :eighteen_share, type: String
    field :eighteen_yoy, type: String
    field :twentysix_count, type: Integer
    field :twentysix_share, type: String
    field :twentysix_yoy, type: String
    field :thirtyfive_count, type: Integer
    field :thirtyfive_share, type: String
    field :thirtyfive_yoy, type: String
    field :fortyfive_count, type: Integer
    field :fortyfive_share, type: String
    field :fortyfive_yoy, type: String
    field :fiftyfive_count, type: Integer
    field :fiftyfive_share, type: String
    field :fiftyfive_yoy, type: String
    field :sixtyfive_count, type: Integer
    field :sixtyfive_share, type: String
    field :sixtyfive_yoy, type: String

    default_scope ->{where(tile: "left_age_group" )}
  end
end