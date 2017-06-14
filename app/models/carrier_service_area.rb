class CarrierServiceArea
  include Mongoid::Document

  field :active_year, type: String
  field :issuer_hios_id, type: String
  field :service_area_id, type: String
  field :service_area_name, type: String
  field :serves_entire_state, type: Boolean, default: false
  field :county_name, type: String
  field :county_code, type: String
  field :state_code, type: String
  field :service_area_zipcode, type: String
  field :partial_county_justification, type: String
  validates_presence_of :service_area_id, :service_area_name, :serves_entire_state, :issuer_hios_id

  validates :county_name, :county_code, :state_code, :service_area_zipcode, presence: true,
    unless: Proc.new { |a| a.serves_entire_state? }

  scope :serving_entire_state, -> { where(serves_entire_state: true) }

  class << self
    def areas_valid_for_zip_code(zip_code:)
      where(service_area_zipcode: zip_code) + serving_entire_state
    end
  end
end
