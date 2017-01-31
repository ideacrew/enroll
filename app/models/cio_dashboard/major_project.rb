module CioDashboard 
  class MajorProject
    include Mongoid::Document
    store_in collection: "cioDashboard"

    field :tile, type: String
    field :project_name, type: String
    field :target_value, type: String
    field :completed_value, type: String

    default_scope ->{where(:tile => "Major Projects")}

    def self.dashboard_stats
        stats =[ ]
        self.all.each do |c|
            stats << {c.project_name => [c.target_value,c.completed_value]} 
        end
        stats
    end
  end
end