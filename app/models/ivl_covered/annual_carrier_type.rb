module IvlCovered
  class AnnualCarrierType
    include Mongoid::Document
    store_in collection: "ivlCovered"

    field :tile , type: String
    field :carrier_first_name, type: String 
    field :carrier_first_select, type: Integer
    field :carrier_first_effectuate, type: Integer
    field :carrier_first_paying, type: Integer
    field :carrier_first_pay_share, type: String
    field :carrier_second_name, type: String
    field :carrier_second_select, type: Integer
    field :carrier_second_effectuate, type: Integer
    field :carrier_second_paying, type: Integer
    field :carrier_second_pay_share, type: String

    default_scope ->{where(tile: "left_carrier" )}
  end
end