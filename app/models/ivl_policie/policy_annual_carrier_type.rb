module IvlPolicie
  class PolicyAnnualCarrierType
    include Mongoid::Document
    store_in collection: "ivlPolicies"

    field :tile , type: String
    field :carrier_first_name, type: String
    field :carrier_first_count, type: Integer
    field :carrier_first_share, type: String
    field :carrier_first_yoy, type: String
    field :carrier_secondName, type: String
    field :carrier_second_count, type: Integer
    field :carrier_second_share, type: String
    field :carrier_second_yoy, type: String

    default_scope ->{where(tile: "left_carrier" )}
  end
end