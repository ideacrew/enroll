class FamilyEnrollmentRenewal

  attr_accessor :enrollment

  def renew
    renewal_enrollment = clone_enrollment
    renewal_enrollment.renew_enrollment
    renewal_enrollment.decorated_hbx_enrollment
    save_renewal_enrollment(renewal_enrollment)
  end

  def clone_enrollment
    renewal_enrollment = @enrollment.family.active_household.hbx_enrollments.new

    renewal_enrollment.consumer_role_id = @active_enrollment.consumer_role_id
    renewal_enrollment.effective_on = HbxProfile.current_hbx.benefit_sponsorship.renewal_benefit_coverage_period.start_on
    renewal_enrollment.coverage_kind = @active_enrollment.coverage_kind
    renewal_enrollment.enrollment_kind = "open_enrollment"
    renewal_enrollment.kind = "individual"
    renewal_enrollment.plan= renewal_plan
    renewal_enrollment.elected_aptc_pct = @active_enrollment.elected_aptc_pct
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
    @active_enrollment.plan.renewal_plan
  end

  def eligible_to_get_covered?(person)
    person.age_on(HbxProfile.current_hbx.benefit_sponsorship.current_benefit_coverage_period.end_on) < 26 || person.is_disabled
  end

  def clone_enrollment_membersx
    hbx_enrollment_members = @active_enrollment.hbx_enrollment_members
    eligible_members = hbx_enrollment_members.select{|hbx_enrollment_member| eligible_to_get_covered?(hbx_enrollment_member.person)}

    eligible_members.inject([]) do |members, hbx_enrollment_member|
      members << HbxEnrollmentMember.new({
        applicant_id: hbx_enrollment_member.applicant_id,
        eligibility_date: HbxProfile.current_hbx.benefit_sponsorship.renewal_benefit_coverage_period.start_on
        coverage_start_on: HbxProfile.current_hbx.benefit_sponsorship.renewal_benefit_coverage_period.start_on
        is_subscriber: hbx_enrollment_member.is_subscriber
      })
    end
  end

  def save_renewal_enrollment(renewal_enrollment)
    if renewal_enrollment.save
      renewal_enrollment
    else
      message = "Enrollment: #{@active_enrollment.id}, \n" \
      "Unable to save renewal enrollment: #{renewal_enrollment.inspect}, \n" \
      "Error(s): \n #{renewal_enrollment.errors.map{|k,v| "#{k} = #{v}"}.join(" & \n")} \n"

      Rails.logger.error { message }
      raise FamilyEnrollmentRenewalFactoryError, message
    end
  end
end