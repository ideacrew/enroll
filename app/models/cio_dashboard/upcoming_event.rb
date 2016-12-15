module CioDashboard 
  class UpcomingEvent
    include Mongoid::Document
    store_in collection: "cioDashboard"
    field :tile, type: String
    field :row_indicator, type: String
    field :event_value, type: String
    field :event_indicator, type: String
    field :impact_value, type: String
    field :impact_indicator,type: String
    field :on_schedule_days_value, type: String
    field :on_schedule_days_indicator, type: String
    field :event_date_value, type: String
    field :event_date_indicator, type: String
  end

end