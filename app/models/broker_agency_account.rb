class BrokerAgencyAccount
  include Mongoid::Document
  include Mongoid::Timestamps


  embedded_in :employer_profile

  # Begin date of relationship
  field :start_on, type: Date
  # End date of relationship
  field :end_on, type: Date
  field :updated_by, type: String

  # Broker agency representing ER
  field :broker_agency_profile_id, type: BSON::ObjectId

  # Broker writing_agent credited for enrollment and transmitted on 834
  field :writing_agent_id, type: BSON::ObjectId
  field :is_active, type: Boolean, default: true

  validates_presence_of :start_on, :broker_agency_profile_id, :is_active
  validate :writing_agent_employed_by_broker

  default_scope   ->{ where(:active => true) }


  # belongs_to broker_agency_profile
  def broker_agency_profile=(new_broker_agency_profile)
    raise ArgumentError.new("expected BrokerAgencyProfile") unless new_broker_agency_profile.is_a?(BrokerAgencyProfile)
    self.broker_agency_profile_id = new_broker_agency_profile._id
    @broker_agency_profile = new_broker_agency_profile
  end

  def broker_agency_profile
    return @broker_agency_profile if defined? @broker_agency_profile
    @broker_agency_profile = employer_profile.organization.broker_agency_profile.where(id: @broker_agency_profile_id) unless @broker_agency_profile_id.blank?
  end

  # belongs_to writing agent (broker)
  def writing_agent=(new_writing_agent)
    raise ArgumentError.new("expected BrokerRole") unless new_writing_agent.is_a?(BrokerRole)
    self.writing_agent_id = new_writing_agent._id
    @writing_agent = new_writing_agent
  end

  def writing_agent
    return @writing_agent if defined? @writing_agent
    @writing_agent = BrokerRole.find(@writing_agent_id) unless @writing_agent_id.blank?
  end

  class << self
    def find(id)
      org = Organization.where(:"employer_profile.broker_agency_accounts._id" => id).first
      org.employer_profile.broker_agency_accounts.detect { |baa| baa._id == id } unless org.blank?
    end

    def find_all_active_by_broker_agency_profile(broker_agency_profile)
      orgs = Organization.where(:"employer_profile.broker_agency_accounts.broker_agency_profile_id" => broker_agency_profile.id).to_a
      orgs.reduce([]) do |list, org| 
        org.employer_profile.broker_agency_accounts.detect { |baa| baa.broker_agency_profile_id == broker_agency_profile.id }
      end
    end
  end

private
  def writing_agent_employed_by_broker
    if writing_agent.present? && broker_agency.present?
      unless broker_agency.writing_agents.detect(writing_agent)
        errors.add(:writing_agent, "must be broker at broker_agency")
      end
    end
  end


end
