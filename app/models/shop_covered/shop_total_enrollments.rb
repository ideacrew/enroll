module ShopCovered
  class ShopTotalEnrollments
    include Mongoid::Document
    store_in collection: "shopCovered"

    field :tile , type: String
    field :active_employers_count, type: Integer
    field :active_employers_change, type: String
    field :employees_enrolled_percentage_count, type: String
    field :employees_enrolled_percentage_change, type: String
    field :total_covered_count, type: Integer
    field :total_covered_change, type: String
    field :month, type: Integer
    field :month_start_count, type: Integer
    field :month_start_change, type: String

    default_scope ->{where(tile: "top" )}
  end
end