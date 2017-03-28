module IvlCovered
  class TotalMetalTypes
    include Mongoid::Document
    store_in collection: "ivlCovered"

    field :tile , type: String
    field :platinum_select, type: Integer
    field :platinum_effectuate, type: Integer
    field :platinum_paying, type: Integer
    field :platinum_pay_share, type: String
    field :gold_select, type: Integer
    field :gold_effectuate, type: Integer
    field :gold_paying, type: Integer
    field :gold_pay_share, type: String
    field :silver_select, type: Integer
    field :silver_effectuate, type: Integer
    field :silver_paying, type: Integer
    field :silver_pay_share, type: String
    field :bronze_select, type: Integer
    field :bronze_effectuate, type: Integer
    field :bronze_paying, type: Integer
    field :bronze_pay_share, type: String
    field :catastrophic_select, type: Integer
    field :catastrophic_effectuate, type: Integer
    field :catastrophic_paying, type: Integer
    field :catastrophic_pay_share, type: String


    default_scope ->{where(tile: "left_metal" )}
  end
end
