module IvlCovered
  class AnnualStatusType
    include Mongoid::Document
    store_in collection: "ivlCovered"

    field :tile , type: String
    field :primary_select, type: Integer
    field :primary_effectuate, type: Integer
    field :primary_paying, type: Integer
    field :primary_pay_share, type: String
    field :dependent_select, type: Integer
    field :dependent_effectuate, type: Integer
    field :dependent_paying, type: Integer
    field :dependent_pay_share, type: String

    default_scope ->{where(tile: "left_status" )}
  end
end