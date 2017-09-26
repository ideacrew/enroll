module ShopWidget
  class EmployeeStatus
    include Mongoid::Document
    store_in collection: "shp"

    field :tile , type: String
    field :status_empl_num, type: Integer
    field :status_empl_pct, type: String
    field :status_dep_num, type: Integer
    field :status_dep_pct, type: String
    
    default_scope ->{where(tile: "status" )}
  end
end