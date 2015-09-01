class IndividualNoticeBuilder < EligibilityNoticeBuilder

  attr_reader :notice
  
  def initialize(consumer, args = {})
    super
    @consumer = consumer
    @to = (@consumer.home_email || @consumer.work_email).address
    @subject = "Eligibility for Health Insurance, Confirmation of Plan Selection"
    @template = args[:template]
    build
  end

  def build
    super
    #@family = Family.find_by_primary_applicant(@consumer)
    #@family = @consumer.primary_family
    #@hbx_enrollments = family.try(:latest_household).try(:hbx_enrollments).active || []
    @members = @hbx_enrollments.map(&:hbx_enrollment_members).flatten.uniq.map(&:person)
  end
  
  def unverfied_ssn_members
    @members
  end
  
  def unverfied_citizenship_members
    @members.select do |m|
      m.consumer_role.lawful_presence_authorized?
    end
  end

  def unverfied_resident_members
    @members.select do |m|
      !m.consumer_role.residency_verified?
    end
  end
  
  def indian_tribe_members
    @members.select do |m|
      m.indian_tribe_member
    end
  end
  
  def members_with_more_plans
    @members
    # @members.map do |m|
    #   if (c = m.plans.count) > 1
    #     [c, m]
    #   end
    # end.compact!
  end
  
  def active_members
    @family.primary_family_member
  end
  
  def inconsistent_members
    @members.select do |m|
      m.consumer_role.identity_verification_denied?
    end
  end
  
  def eligible_immigration_status_members
    @members.select do |m|
      m.eligible_immigration_status
    end
  end
  
end
