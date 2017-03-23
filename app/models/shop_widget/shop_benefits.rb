module ShopWidget
  class ShopBenefits
    include Mongoid::Document
    store_in collection: "shopPolicies"

    field :tile , type: String
    field :date_of_count, type: Integer
    field :date_of_share, type: String
    field :date_of_yoy, type: String
    field :first_month_count, type: Integer
    field :first_month_share, type: String
    field :first_month_yoy, type: String

    field :first_thirty_count, type: Integer
    field :first_thirty_share, type: String
    field :first_thirty_yoy, type: String
    field :first_sixty_count, type: Integer
    field :first_sixty_share, type: String
    field :first_sixty_yoy, type: String
    
    default_scope ->{where(tile: "left_benefits" )}
  end
end