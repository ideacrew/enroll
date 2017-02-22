module CioDashboard
  class Redmine
    include Mongoid::Document
    store_in collection: "cioDashboard"
    field :tile, type: String
    field :row_indicator, type: String
    field :ticket_type, type: String
    field :total_open_value, type: Integer
    field :total_open_indicator, type: String
    field :closed_7_day_value, type: Integer
    field :closed_7_day_indicator,type: String
    field :opened_7_day_value, type: Integer
    field :opened_7_day_indicator, type: String
    field :avg_days_value, type: Float
    field :avg_days_indicator, type: String
    field :target_days_value, type: Integer
    field :target_days_indicator, type: String
    field :index_value, type: Integer
    field :index_indicator, type: String
    field :change_7_day_value, type: Integer
    field :change_7_day_indicator, type: String
  
  

   def self.redmine_dashboard_stats
        redmines =[ ]
        CioDashboard::Redmine.all.each do |r|
            redmines << r if r.total_open_value.present? && redmines.size < 7 
        end
        redmines
    end

    end

end

