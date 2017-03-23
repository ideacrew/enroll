module ShopWidget
  class EmployerContributions
    include Mongoid::Document
    store_in collection: "shopPolicies"

    field :tile , type: String
    field :hundred_count, type: Integer
    field :hundred_share, type: String
    field :hundred_yoy, type: String
    field :fiftyone_count, type: Integer
    field :fiftyone_share, type: String
    field :fiftyone_yoy, type: String
    field :fifty_count, type: Integer
    field :fifty_share, type: String
    field :fifty_yoy, type: String

    default_scope ->{where(tile: "left_contribution" )}
  end
end