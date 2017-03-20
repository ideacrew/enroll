module ShopCovered
  class ShopStatusWidget
    include Mongoid::Document
    store_in collection: "shopCovered"

    field :tile , type: String
    field :employee_count, type: Integer
    field :employee_share, type: String
    field :employee_yoy, type: String
    field :dependent_count, type: Integer
    field :dependent_share, type: String
    field :dependent_yoy, type: String

    default_scope ->{where(tile: "left_status" )}
  end
end