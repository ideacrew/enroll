module IvlCovered
  class AnnualStatusType
    include Mongoid::Document
    store_in collection: "ivlCovered"

    field :tile , type: String
    field :primary_select, type: Integer
    field :primary_effectuate, type: String
    field :primary_paying, type: String
    field :primary_pay_share, type: String
    field :dependent_select, type: String
    field :dependent_effectuate, type: String
    field :dependent_paying, type: String
    field :dependent_pay_share, type: String

    default_scope ->{where(tile: "left_status" )}
  end
end