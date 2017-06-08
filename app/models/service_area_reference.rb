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

  class << self
    def areas_valid_for_zip_code(zip_code:)
      where(service_area_zipcode: zip_code) + self.serving_entire_state.to_a
    end

    def service_areas_for(office_location)
      address = office_location.address
      areas_valid_for_zip_code(zip_code: address.zip)
    end

    def valid_for?(office_location: , carrier_profile:)
      where(service_area_zipcode: office_location.address.zip, hios_id: carrier_profile.hbx_carrier_id).any?
    end
  end

end
