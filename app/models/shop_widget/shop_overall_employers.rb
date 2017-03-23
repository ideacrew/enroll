module ShopWidget
  class ShopOverallEmployers
    include Mongoid::Document
    store_in collection: "shopPolicies"

    field :tile , type: String
    field :active_employers_count, type: Integer
    field :active_employers_change, type: String
    field :new_employers_count, type: String
    field :new_employers_change, type: String
    field :total_policies_count, type: Integer
    field :total_policies_change, type: String
    field :month, type: Integer
    field :month_policies_count, type: Integer
    field :month_policies_change, type: String

    default_scope ->{where(tile: "top" )}
  end
end