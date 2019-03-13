class BrokerAgencyProfile

  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :organization

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

  def primary_broker_role=(new_primary_broker_role = nil)
    if new_primary_broker_role.present?
      raise ArgumentError.new("expected BrokerRole class") unless new_primary_broker_role.is_a? BrokerRole
      self.primary_broker_role_id = new_primary_broker_role._id
    else
      unset("primary_broker_role_id")
    end
    @primary_broker_role = new_primary_broker_role
  end

  def primary_broker_role
    return @primary_broker_role if defined? @primary_broker_role
    @primary_broker_role = BrokerRole.find(self.primary_broker_role_id) unless primary_broker_role_id.blank?
  end

  class << self
    def find(id)
      organizations = Organization.where("broker_agency_profile._id" => BSON::ObjectId.from_string(id)).to_a
      organizations.size > 0 ? organizations.first.broker_agency_profile : nil
    end
  end
end
