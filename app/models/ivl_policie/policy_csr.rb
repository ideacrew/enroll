module IvlPolicie
  class PolicyCsr
    include Mongoid::Document
    store_in collection: "ivlPolicies"

    field :tile , type: String
    field :yes_count, type: Integer
    field :yes_share, type: String
    field :yes_yoy, type: String
    field :no_count, type: Integer
    field :no_share, type: String
    field :no_yoy, type: String
    
    default_scope ->{where(tile: "left_csr" )}
  end
end