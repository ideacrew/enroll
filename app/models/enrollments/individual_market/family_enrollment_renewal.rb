class Enrollments::IndividualMarket::FamilyEnrollmentRenewal

  attr_accessor :enrollment, :renewal_benefit_coverage_period

  def initialize
    @logger = Logger.new("#{Rails.root}/log/ivl_enrollment_renewal_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
  end

  def renew
    begin
      renewal_enrollment = clone_enrollment
      renewal_enrollment.renew_enrollment
      renewal_enrollment.decorated_hbx_enrollment
      save_renewal_enrollment(renewal_enrollment)
    rescue Exception => e
      @logger.info "Enrollment renewal failed for #{enrollment.hbx_id} with Exception: #{e.to_s}"
    end
  end

  def clone_enrollment
    renewal_enrollment = @enrollment.family.active_household.hbx_enrollments.new

    renewal_enrollment.consumer_role_id = @enrollment.consumer_role_id
    renewal_enrollment.effective_on = @renewal_benefit_coverage_period.start_on
    renewal_enrollment.coverage_kind = @enrollment.coverage_kind
    renewal_enrollment.enrollment_kind = "open_enrollment"
    renewal_enrollment.kind = "individual"
    renewal_enrollment.plan = renewal_plan
    renewal_enrollment.elected_aptc_pct = @enrollment.elected_aptc_pct
    renewal_enrollment.hbx_enrollment_members = clone_enrollment_members
    renewal_enrollment
  end

  # Assisted
  # Tax household > eligibility determinations
  #  - latest eligibility determation
  #  - current CSR elgibility kind
  #  - max APTC
  def renewal_eligiblity_determination
  end

  # Cat plan ageoff
  # Eligibility determination CSR change
  def renewal_plan
    renewal_plan = @enrollment.plan.renewal_plan
    if renewal_plan.blank?
      raise "2017 renewal plan missing on HIOS id #{@enrollment.plan.hios_id}"
    end
    renewal_plan
  end

  def eligible_to_get_covered?(person)
    person.age_on(HbxProfile.current_hbx.benefit_sponsorship.current_benefit_coverage_period.end_on) < 26 || person.is_disabled
  end

  def eligible_enrollment_members
    child_relations = %w(child ward foster_child adopted_child)

    @enrollment.hbx_enrollment_members.reject do |member|
      child_relations.include?(member.family_member.relationship) && !eligible_to_get_covered?(member.person)
    end
  end

  def clone_enrollment_members
    eligible_enrollment_members.inject([]) do |members, hbx_enrollment_member|
      members << HbxEnrollmentMember.new({
        applicant_id: hbx_enrollment_member.applicant_id,
        eligibility_date: @renewal_benefit_coverage_period.start_on,
        coverage_start_on: @renewal_benefit_coverage_period.start_on,
        is_subscriber: hbx_enrollment_member.is_subscriber
      })
    end
  end

  def save_renewal_enrollment(renewal_enrollment)
    if renewal_enrollment.save
      renewal_enrollment
    else
      message = "Enrollment: #{@enrollment.hbx_id}, \n" \
      "Error(s): \n #{renewal_enrollment.errors.map{|k,v| "#{k} = #{v}"}.join(" & \n")} \n"
      
      @logger.info message
    end
  end
end