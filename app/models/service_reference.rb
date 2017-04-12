class ServiceReference
  include Mongoid::Document

  field :service_area_id, type: String
  field :service_area_name, type: String
  field :state, type: Boolean, default: false
  field :county_name, type: String
  field :partial_county, type: Boolean, default: false
  field :service_area_zipcode, type: String
  field :partial_county_justification, type: String
  validates_presence_of :service_area_id, :service_area_name, :state 
end
