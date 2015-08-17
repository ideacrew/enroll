class CoverageHousehold
  include Mongoid::Document
  include Mongoid::Timestamps
  include AASM
  include HasFamilyMembers

  # The pool of all applicants eligible for enrollment during a certain time period

  embedded_in :household

  # all coverage_household members are immediate relations
  field :is_immediate_family, type: Boolean

  # coverage household includes immediate relations with non-QHP eligibility determination 
  field :is_determination_split_household, type: Boolean, default: false

  # Agency representing this coverage household
  field :broker_agency_id, type: BSON::ObjectId

  # Broker agent credited for enrollment and transmitted on 834
  field :writing_agent_id, type: BSON::ObjectId

  field :aasm_state, type: String, default: "applicant"
  field :submitted_at, type: DateTime

  embeds_many :coverage_household_members, cascade_callbacks: true
  accepts_nested_attributes_for :coverage_household_members

  validates_presence_of :is_immediate_family
  validate :presence_of_coverage_household_members

  # belongs_to writing agent (broker_role)
  def writing_agent=(new_writing_agent)
    raise ArgumentError.new("expected BrokerRole class") unless new_writing_agent.is_a? BrokerRole
    self.new_writing_agent_id = new_writing_agent._id
    @writing_agent = new_writing_agent
  end

  def writing_agent
    return @writing_agent if defined? @writing_agent
    @writing_agent = BrokerRole.find(self.writing_agent_id) unless writing_agent_id.blank?
  end

  # belongs_to BrokerAgencyProfile
  def broker_agency_profile=(new_broker_agency)
    raise ArgumentError.new("expected BrokerAgencyProfile") unless new_broker_agency.is_a? BrokerAgencyProfile
    self.broker_agency_id = new_broker_agency._id
    @broker_agency_profile = new_broker_agency
  end

  def broker_agency_profile
    return @broker_agency_profile if defined? @broker_agency_profile
    @broker_agency_profile = BrokerAgencyProfile.find(self.broker_agency_id) unless broker_agency_id.blank?
  end

  def subscriber
    coverage_household_members.detect(&:is_subscriber)
  end

  def family
    return nil unless household
    household.family
  end

  def applicant_ids
    coverage_household_members.map(&:family_member_id)
  end

  def remove_family_member(member)
    family_member = coverage_household_members.detect { |ch_member| ch_member.family_member_id.to_s == member.id.to_s }
    if family_member.present?
       coverage_household_members.delete(family_member)
    end
  end

  aasm do
    state :unverified, initial: true
    state :enrollment_submitted
    state :enrolled_contingent
    state :enrolled
    state :canceled
    state :terminated

    event :submit_enrollment do
      transitions from: :unverified, to: :enrollment_submitted
    end


    event :ivl_benefit_selected do
      transitions from: :applicant, to: :ivl_enrollment_eligible, :guards => [:is_identity_proved?, :is_lawfully_present?, :is_state_resident?]
      transitions from: :applicant, to: :ivl_enrollment_contingent, :guard => :has_ineligible_period_expired?
    end

    event :ivl_benefit_purchased do
    end
  end


private
  def presence_of_coverage_household_members
    if self.coverage_household_members.size == 0
      self.errors.add(:base, "Should have at least one coverage_household_member")
    end
  end


end
