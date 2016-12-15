module CioDashboard
  class Pipeline
    include Mongoid::Document
    store_in collection: "cioDashboard"
    field :tile, type: String
    field :row_indicator, type: String
    field :effective_month, type: DateTime
    field :est_convert_value, type: String
    field :est_convert_indicator, type: String
    field :real_convert_value, type: String
    field :real_convert_indicator,type: String
    field :est_renew_value, type: String
    field :event_date_indicator, type: String
    field :est_renew_indicator, type: String
    field :real_renew_value, type: String
    field :real_renew_indicator, type: String
    field :est_new_value, type: String
    field :est_new_indicator, type: String
    field :real_new_value, type: String
    field :real_new_indicator, type: String
  end
end

