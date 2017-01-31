module CioDashboard
  class WebActivity
    include Mongoid::Document
    store_in collection: "cioDashboard"
    field :apdex_value, type: String
    field :page_views_value, type: String
    field :new_visitors_value, type: String
    field :return_visitors_value, type: String
    field :load_time_value, type: String
    field :avg_session_value, type: String
    
    def self.webactivity_dashboard_stats
        webactivitys =[ ]
        CioDashboard::WebActivity.all.each do |wa|
            webactivitys << wa if wa.apdex_value.present? && webactivitys.size < 5 
        end
        webactivitys
    end
  end
end