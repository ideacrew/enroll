class ServiceVisit
  include Mongoid::Document
  include Mongoid::Timestamps

  field :copay_in_network, type: String
  field :co_insurance_in_network, type: String
  field :in_network_result, type: String
end