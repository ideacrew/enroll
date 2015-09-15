class IvlNotices::IndividualNoticeBuilder < IvlNotices::EligibilityNoticeBuilder

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
    @members = @hbx_enrollments.map(&:hbx_enrollment_members).flatten.map(&:person).try(:uniq)
    init_benefit
    append_individual
  end

  def create_notice
    generate_notice
    attach_blank_page
    attach_dchl_rights
    prepend_envelope
  end

  def init_benefit
    bc_period = HbxProfile.current_hbx.benefit_sponsorship.benefit_coverage_periods.select { |bcp| bcp.start_on.year == 2015 }.first
    pkgs = bc_period.benefit_packages
    benefit_package = pkgs.select{|plan|  plan[:title] == "individual_health_benefits_2015"}
    @benefit = benefit_package.first
  rescue
    nil
  end

  def append_individual
    @notice.individual = PdfTemplates::Individual.new
    %w(ineligible_members ineligible_members_due_to_residency ineligible_members_due_to_incarceration ineligible_members_due_to_immigration active_members inconsistent_members eligible_immigration_status_members members_with_more_plans indian_tribe_members unverfied_resident_members unverfied_citizenship_members unverfied_ssn_members).each do |method_name|
      member_names = self.public_send(method_name).inject([]) do |names, member|
        names << member.try(:full_name).try(:titleize)
      end
      @notice.individual.public_send("#{method_name}=", member_names)
    end
  end

  def ineligible_members
    @family.active_family_members.map(&:person) - @members rescue []
  end

  def ineligible_members_due_to_residency
    ineligible_members.select do |person|
      if person.try(:consumer_role).blank? || @benefit.blank?
        false
      else
        InsuredEligibleForBenefitRule.new(person.consumer_role, @benefit).is_residency_status_satisfied?
      end
    end
  end

  def ineligible_members_due_to_incarceration
    ineligible_members.select do |person|
      if person.try(:consumer_role).blank? || @benefit.blank?
        false
      else
        InsuredEligibleForBenefitRule.new(person.consumer_role, @benefit).is_incarceration_status_satisfied?
      end
    end
  end

  # Ineligible Due to Citizenship/Immigration
  def ineligible_members_due_to_immigration
    ineligible_members.select do |person|
      if person.try(:consumer_role).blank? || @benefit.blank?
        false
      else
        InsuredEligibleForBenefitRule.new(person.consumer_role, @benefit).is_citizenship_status_satisfied?
      end
    end
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
    @family.primary_family_member.to_a rescue []
  end
  
  def inconsistent_members
    @members.select do |m|
      m.consumer_role.try(:identity_verification_denied?)
    end
  end
  
  def eligible_immigration_status_members
    @members.select do |m|
      m.eligible_immigration_status
    end
  end
  
end
