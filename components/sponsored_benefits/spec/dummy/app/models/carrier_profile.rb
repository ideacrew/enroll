class CarrierProfile
  include Mongoid::Document
  include Config::AcaModelConcern
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
  field :offers_sole_source, type: Boolean, default: false

  field :issuer_hios_ids, type: Array, default: []
  field :issuer_state, type: String, default: aca_state_abbreviation
  field :market_coverage, type: String, default: "shop (small group)" # or individual
  field :dental_only_plan, type: Boolean, default: false

  def self.for_issuer_hios_id(issuer_id)
    Organization.where("carrier_profile.issuer_hios_ids" => issuer_id).map(&:carrier_profile)
  end
end
