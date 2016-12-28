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

     def self.fundtransfer_dashboard_stats
        fundtransfers =[ ]
        CioDashboard::FundTransfer.all.each do |ft|
            fundtransfers << ft if ft.amount.present? && fundtransfers.size < 5 
        end
        fundtransfers
    end
  end
end

