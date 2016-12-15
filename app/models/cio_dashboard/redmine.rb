module CioDashboard
  class Redmine
    include Mongoid::Document
    store_in collection: "cioDashboard"
    field :tile, type: String
    field :row_indicator, type: String
    field :ticket_type, type: String
    field :total_open_value, type: String
    field :total_open_indicator, type: String
    field :closed_7_day_value, type: String
    field :closed_7_day_indicator,type: String
    field :opened_7_day_value, type: String
    field :opened_7_day_indicator, type: String
    field :avg_days_value, type: String
    field :avg_days_indicator, type: String
    field :target_days_value, type: String
    field :target_days_indicator, type: String
    field :index_value, type: String
    field :index_indicator, type: String
    field :change_7_day_value, type: String
    field :change_7_day_indicator, type: String
  
  end

end

