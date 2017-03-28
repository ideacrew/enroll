module IvlCovered
  class OverallAgeGroups
    include Mongoid::Document
    store_in collection: "ivlCovered"

    field :tile , type: String
    field :zero_select, type: Integer
    field :zero_effectuate, type: Integer
    field :zero_paying, type: Integer
    field :zero_pay_share, type: String
    field :one_select, type: Integer
    field :one_effectuate, type: Integer
    field :one_paying, type: Integer
    field :one_pay_share, type: String
    field :eighteen_select, type: Integer
    field :eighteen_effectuate, type: Integer
    field :eighteen_paying, type: Integer
    field :eighteen_pay_share, type: String
    field :twentysix_select, type: Integer
    field :twentysix_effectuate, type: Integer
    field :twentysix_paying, type: Integer
    field :twentysix_pay_share, type: String
    field :thirtyfive_select, type: Integer
    field :thirtyfive_effectuate, type: Integer
    field :thirtyfive_paying, type: Integer
    field :thirtyfive_pay_share, type: Integer
    field :fiftyfive_select, type: Integer
    field :fiftyfive_effectuate, type: Integer
    field :fiftyfive_paying, type: Integer
    field :fortyfive_select, type: Integer
    field :fortyfive_effectuate, type: Integer
    field :fortyfive_paying, type: Integer
    field :fortyfive_pay_share, type: String
    field :fiftyfive_pay_share, type: String
    field :sixtyfive_select, type: Integer
    field :sixtyfive_effectuate, type: Integer
    field :sixtyfive_paying, type: Integer
    field :sixtyfive_pay_share, type: String
    
    default_scope ->{where(tile: "left_age_group" )}
  end
end

   