module CioDashboard 
  class MajorProject
    include Mongoid::Document
    store_in collection: "cioDashboard"
    field :tile, type: String
    field :project_name, type: String
    field :target_value, type: String
    field :completed_value, type: String

  end
end

