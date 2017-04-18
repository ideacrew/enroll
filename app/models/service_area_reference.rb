class ServiceAreaReference
  include Mongoid::Document

  field :service_area_id, type: String
  field :service_area_name, type: String
  field :serves_entire_state, type: Boolean, default: false
  field :county_name, type: String
  field :serves_partial_county, type: Boolean, default: false
  field :service_area_zipcode, type: String
  field :partial_county_justification, type: String
  validates_presence_of :service_area_id, :service_area_name, :serves_entire_state

  validates :county_name, :serves_partial_county, presence: true,
   unless: Proc.new { |a| a.serves_entire_state? }
  validates :partial_county_justification, :service_area_zipcode, presence: true,
   if: Proc.new { |a| a.serves_partial_county? }
end
