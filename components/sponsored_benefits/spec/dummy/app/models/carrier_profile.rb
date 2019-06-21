class CarrierProfile
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :organization

  # temporary field for importing seed files
  field :hbx_carrier_id, type: Integer

  field :abbrev, type: String
  field :associated_carrier_profile_id, type: BSON::ObjectId

  field :ivl_health, type: Boolean
  field :ivl_dental, type: Boolean
  field :shop_health, type: Boolean
  field :shop_dental, type: Boolean

  field :issuer_hios_id, type: String
  field :issuer_state, type: String, default: "DC"
  field :market_coverage, type: String, default: "shop (small group)" # or individual
  field :dental_only_plan, type: Boolean, default: false


  delegate :hbx_id, to: :organization, allow_nil: true
  delegate :legal_name, :legal_name=, to: :organization, allow_nil: false
  delegate :dba, :dba=, to: :organization, allow_nil: true
  delegate :fein, :fein=, to: :organization, allow_nil: false
  delegate :is_active, :is_active=, to: :organization, allow_nil: false
  delegate :updated_by, :updated_by=, to: :organization, allow_nil: false

  class << self
    def find(id)
      organizations = Organization.where("carrier_profile._id" => BSON::ObjectId.from_string(id.to_s)).to_a
      organizations.size > 0 ? organizations.first.carrier_profile : nil
    end
  end
end
