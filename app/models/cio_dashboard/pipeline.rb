module CioDashboard
  class Pipeline
    include Mongoid::Document
    store_in collection: "cioDashboard"
    field :tile, type: String
    field :row_indicator, type: String
    field :effective_month, type: String
    field :est_convert_value, type: Integer
    field :est_convert_indicator, type: String
    field :real_convert_value, type: Integer
    field :real_convert_indicator,type: String
    field :est_renew_value, type: Integer
    field :event_date_indicator, type: String
    field :est_renew_indicator, type: String
    field :real_renew_value, type: Integer
    field :real_renew_indicator, type: String
    field :est_new_value, type: Integer
    field :est_new_indicator, type: String
    field :real_new_value, type: Integer
    field :real_new_indicator, type: String


    def self.pipeline_dashboard_stats
        pipelines =[ ]
        CioDashboard::Pipeline.all.each do |p|
            pipelines << p if p.tile.present? && pipelines.size < 5 
        end
        pipelines
    end
  end
end

