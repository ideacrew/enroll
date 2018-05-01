class BrokerAgencyStaffRole
  include Mongoid::Document

  embedded_in :person
  field :aasm_state, type: String, default: "broker_agency_pending"
  field :reason, type: String
  field :broker_agency_profile_id, type: BSON::ObjectId

end
