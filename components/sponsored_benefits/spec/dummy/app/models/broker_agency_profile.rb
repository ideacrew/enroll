class BrokerAgencyProfile

  include Mongoid::Document
  include Mongoid::Timestamps

  field :entity_kind, type: String
  field :market_kind, type: String
  field :corporate_npn, type: String
  field :primary_broker_role_id, type: BSON::ObjectId
  field :default_general_agency_profile_id, type: BSON::ObjectId

  field :languages_spoken, type: Array, default: ["en"] # TODO
  field :working_hours, type: Boolean, default: false
  field :accept_new_clients, type: Boolean

  field :aasm_state, type: String
  field :aasm_state_set_on, type: Date

  def self.find(id)
  end
end
