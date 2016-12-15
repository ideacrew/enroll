module CioDashboard 
  class FundTransfer
    include Mongoid::Document
    store_in collection: "cioDashboard"
    field :tile, type: String
    field :row_indicator, type: String
    field :carrier, type: String
    field :amount, type: String
    field :month_change_value, type: String
    field :month_change_indicator, type: String
    field :year_change_value,type: String
    field :year_change_indicator, type: String
  end
end

