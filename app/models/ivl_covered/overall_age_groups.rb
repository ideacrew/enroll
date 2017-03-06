module IvlCovered
  class OverallAgeGroups
    include Mongoid::Document
    store_in collection: "ivlCovered"

    field :tile , type: String
    field :zero_count, type: String
    field :zero_share, type: String
    field :zero_yoy, type: String
    field :one_count, type: String
    field :one_share, type: String
    field :one_yoy, type: String
    field :eighteen_count, type: String
    field :eighteen_share, type: String
    field :eighteen_yoy, type: String
    field :twentysix_count, type: String
    field :twentysix_share, type: String
    field :twentysix_yoy, type: String
    field :thirtyfive_count, type: String
    field :thirtyfive_share, type: String
    field :thirtyfive_yoy, type: String
    field :fortyfive_count, type: String
    field :fortyfive_share, type: String
    field :fortyfive_yoy, type: String
    field :fiftyfive_count, type: String
    field :fiftyfive_share, type: String
    field :fiftyfive_yoy, type: String
    field :sixtyfive_count, type: String
    field :sixtyfive_share, type: String
    field :sixtyfive_yoy, type: String

    default_scope ->{where(tile: "left_age_group" )}
  end
end