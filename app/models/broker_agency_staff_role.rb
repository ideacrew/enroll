class BrokerAgencyStaffRole
  include Mongoid::Document
  include MongoidSupport::AssociationProxies

  embedded_in :person
  field :broker_agency_profile_id, type: BSON::ObjectId

  associated_with_one :broker_agency_profile, :broker_agency_profile_id, "BrokerAgencyProfile"

  validates_presence_of :broker_agency_profile_id
end
