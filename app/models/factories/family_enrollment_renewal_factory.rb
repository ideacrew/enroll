module Factories
  class FamilyEnrollmentRenewalFactory
    include Mongoid::Document

    attr_accessor :family

    def renew
      # Collect active enrollments -- 
      # collect waived coverage
      @family.enrollments.each do |active_enrollment|

        renewal_enrollment = @family.active_household.hbx_enrollments.new
        renewal_enrollment = assign_common_attributes(active_enrollment, renewal_enrollment)

        if active_enrollment.kind == "employer_sponsored"
          renewal_enrollment = clone_shop_enrollment(active_enrollment, renewal_enrollment)
        else
          renewal_enrollment = clone_ivl_enrollment(active_enrollment, renewal_enrollment)          
        end

        # enrollment_kind == "special_enrollment" || "open_enrollment"

        renewal_enrollment.renew_enrollment
        if renewal_enrollment.save
          renewal_enrollment
        else
          raise FamilyEnrollmentRenewalFactoryError, 
            "For enrollment: #{renewal_enrollment.inspect}, \n" \
            "Error(s): \n #{renewal_enrollment.errors.map{|k,v| "#{k} = #{v}"}.join(" & \n")} \n" \
            "Unable to save renewal enrollment: #{renewal_enrollment.inspect}"
        end
      end
    end

    def assign_common_attributes(active_enrollment, renewal_enrollment)
      common_attributes = %w(coverage_household_id coverage_kind changing broker_agency_profile_id 
          writing_agent_id original_application_type kind
        )
      common_attributes.each do |attr|
         renewal_enrollment.send("#{attr}=", active_enrollment.send(attr))
      end

      renewal_enrollment.plan_id = active_enrollment.plan.renewal_plan_id
      renewal_enrollment
    end

    def clone_moc_enrollment
    end

    def clone_ivl_enrollment
      # consumer_role_id
      # elected_amount
      # elected_premium_credit
      # applied_premium_credit
      # elected_aptc_amount
      # applied_aptc_amount

      # renewal_enrollment.renew_coverage
    end

    def clone_shop_enrollment(active_enrollment, renewal_enrollment)
      # Find and associate with new ER benefit group

      renewal_enrollment.employee_role_id = active_enrollment.employee_role_id

      renewal_enrollment.benefit_group_id = active_enrollment.benefit_group_id

      employee = active_enrollment.household.family.primary_family_member

      census_employee = CensusEmployee.matchable(employee.ssn, employee.dob).first
      if census_employee.blank?
        raise FamilyEnrollmentRenewalFactoryError, "Unable to find census_employee for primary family member: #{employee.inspect} for hbx_enrollment #{active_enrollment.id}"
      end

      benefit_group_assignment = census_employee.renewal_benefit_group_assignment
      if benefit_group_assignment.blank?
        raise FamilyEnrollmentRenewalFactoryError, "Unable to find benefit_group_assignment for census_employee: #{census_employee.inspect} for hbx_enrollment #{active_enrollment.id}"
      end

      renewal_enrollment.benefit_group_assignment_id = benefit_group_assignment.id

      # benefit_group_assignment_id
      renewal_enrollment.effective_on = benefit_group_assignment.benefit_group.start_on

      # Set the HbxEnrollment to proper state
      # Renew waiver status
      if active_enrollment.inactive? 
        renewal_enrollment.waiver_reason = active_enrollment.waiver_reason
        renewal_enrollment.waive_coverage 
      end

      renewal_enrollment.hbx_enrollment_members = active_enrollment.hbx_enrollment_members
      renewal_enrollment
    end

    # Validate enrollment membership against benefit package-covered relationships
    def family_eligibility(active_enrollment, renewal_enrollment)

      coverage_household.coverage_household_members.each do |coverage_member|
        enrollment_member = HbxEnrollmentMember.new_from(coverage_household_member: coverage_member)
        enrollment_member.eligibility_date = enrollment.effective_on
        enrollment_member.coverage_start_on = enrollment.effective_on
        renewal_enrollment.hbx_enrollment_members << enrollment_member
      end

      renewal_enrollment.hbx_enrollment_members
    end

  end
  
  class FamilyEnrollmentRenewalFactoryError < StandardError; end
end
