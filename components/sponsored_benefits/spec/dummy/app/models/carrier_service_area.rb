class CarrierServiceArea
  include Mongoid::Document
  include Config::AcaModelConcern

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

  scope :for_issuer, -> (hios_ids) { where(issuer_hios_id: { "$in" => hios_ids }) }
end
