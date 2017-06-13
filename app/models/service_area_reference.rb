class ServiceAreaReference
  include Mongoid::Document

  field :hios_id, type: String
  field :service_area_id, type: String
  field :service_area_name, type: String
  field :serves_entire_state, type: Boolean, default: false
  field :county_name, type: String
  field :county_code, type: String
  field :state_code, type: String
  field :serves_partial_county, type: Boolean, default: false
  field :service_area_zipcode, type: String
  field :partial_county_justification, type: String
  validates_presence_of :service_area_id, :service_area_name, :serves_entire_state, :hios_id

  validates :county_name, :county_code, :state_code, :serves_partial_county, :service_area_zipcode, presence: true,
    unless: Proc.new { |a| a.serves_entire_state? }
  validates :partial_county_justification, presence: true,
    if: Proc.new { |a| a.serves_partial_county? }
  
  scope :serving_entire_state, -> { where(serves_entire_state: true) }

  def self.areas_valid_for_zip_code(zip_code:)
    self.where(service_area_zipcode: zip_code) + self.serving_entire_state.to_a
  end
end
