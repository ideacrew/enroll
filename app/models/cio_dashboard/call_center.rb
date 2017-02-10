module CioDashboard
  class CallCenter
    include Mongoid::Document
    store_in collection: "cioDashboard"
    field :received_value, type: Integer
    field :answered_value, type: Integer
    field :abandoned_value, type: Integer
    field :avg_wait_value, type: String
    field :max_wait_value, type: String
    
    def self.callcenter_dashboard_stats
        callcenters =[ ]
        CioDashboard::CallCenter.all.each do |c|
            callcenters << c if c.received_value.present? && callcenters.size < 5 
        end
        callcenters
    end
  end
end
