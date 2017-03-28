module IvlCovered
  class OverallGenderTypes
    include Mongoid::Document
    store_in collection: "ivlCovered"

    field :tile , type: String
    field :male_select, type: Integer
    field :male_effectuate, type: Integer
    field :male_paying, type: Integer
    field :male_pay_share, type: String
    field :female_select, type: Integer
    field :female_effectuate, type: Integer
    field :female_paying, type: Integer
    field :female_pay_share, type: String
    
    default_scope ->{where(tile: "left_gender" )}
  end
end