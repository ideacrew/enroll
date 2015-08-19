class CoverageHousehold
  include Mongoid::Document
  include Mongoid::Timestamps
  include HasFamilyMembers

  # The pool of all applicants eligible for enrollment during a certain time period

  embedded_in :household

  # all coverage_household members are immediate relations
  field :is_immediate_family, type: Boolean

  # coverage household includes immediate relations with non-QHP eligibility determination 
  field :is_determination_split_household, type: Boolean, default: false

  field :submitted_at, type: DateTime

  embeds_many :coverage_household_members, cascade_callbacks: true
  accepts_nested_attributes_for :coverage_household_members

  validates_presence_of :is_immediate_family
  validate :presence_of_coverage_household_members

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
  
  def notify_the_user(member)
    if member.person && (role = member.person.consumer_role)
      if role.is_hbx_enrollment_eligible? && role.identity_verified_date
        IvlNotificationMailer.lawful_presence_verified(role)
      elsif role.is_hbx_enrollment_eligible? && role.identity_verification_pending?
        IvlNotificationMailer.lawful_presence_unverified(role)
      elsif !role.is_hbx_enrollment_eligible?
        IvlNotificationMailer.lawfully_ineligible(role)
      end
    end
  end
  

private
  def presence_of_coverage_household_members
    if self.coverage_household_members.size == 0
      self.errors.add(:base, "Should have at least one coverage_household_member")
    end
  end


end
