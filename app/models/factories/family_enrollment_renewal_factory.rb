module Factories
  class FamilyEnrollmentRenewalFactory
    include Mongoid::Document

    attr_accessor :family

    def renew
      raise ArgumentError unless defined?(@family)

      shop_enrollments = @family.enrollments.shop_market + @family.active_household.hbx_enrollments.waived

      if shop_enrollments.any?
        @census_employee = get_census_employee(shop_enrollments.first)

        if @census_employee.present?
          shop_enrollments.each do |active_enrollment|       
            next unless active_enrollment.currently_active?

            # renewal_enrollment = renewal_builder.call(active_enrollment)
            renewal_enrollment = renewal_builder(active_enrollment)
            renewal_enrollment = clone_shop_enrollment(active_enrollment, renewal_enrollment)

            renewal_enrollment.decorated_hbx_enrollment # recalc the premium amounts
            save_renewal_enrollment(renewal_enrollment, active_enrollment)
          end
        end
      end

      # @family.enrollments.individual_market do |active_enrollment|       
      #   next unless active_enrollment.currently_active?

      #   renewal_enrollment = renewal_builder.call(active_enrollment)
      #   renewal_enrollment = clone_ivl_enrollment(active_enrollment, renewal_enrollment)
      #   save_renewal_enrollment(renewal_enrollment, active_enrollment)        
      # end

      # enrollment_kind == "special_enrollment" || "open_enrollment"
    end

    def renewal_builder(active_enrollment)
      renewal_enrollment = @family.active_household.hbx_enrollments.new
      renewal_enrollment = assign_common_attributes(active_enrollment, renewal_enrollment)
      renewal_enrollment.renew_enrollment
      renewal_enrollment
    end

    def get_census_employee(active_enrollment)
      employee = active_enrollment.household.family.primary_family_member
      census_employee = CensusEmployee.by_ssn(employee.ssn).active.first
      
      if census_employee.blank?
        message = "Unable to find census_employee for "\
          "primary family member: #{employee.full_name} "\
          "id: #{employee.id} "\
          "for hbx_enrollment: #{active_enrollment.id}"

        Rails.logger.error { message }
        raise FamilyEnrollmentRenewalFactoryError, message
      else
        census_employee
      end
    end

    # def display_premiums(enrollment)
    #   puts "#{enrollment.aasm_state.humanize} enrollment amounts-------"
    #   puts enrollment.total_premium
    #   puts enrollment.total_employer_contribution
    #   puts enrollment.total_employee_cost
    #   puts "member premiums #{enrollment.hbx_enrollment_members.map(&:premium_amount)}"
    #   puts "---------------------------------"
    # end

    def save_renewal_enrollment(renewal_enrollment, active_enrollment)
      if renewal_enrollment.save
        renewal_enrollment
      else
        message = "Enrollment: #{active_enrollment.id}, \n" \
        "Unable to save renewal enrollment: #{renewal_enrollment.inspect}, \n" \
          "Error(s): \n #{renewal_enrollment.errors.map{|k,v| "#{k} = #{v}"}.join(" & \n")} \n"

        Rails.logger.error { message }
        raise FamilyEnrollmentRenewalFactoryError, message
      end
    end

    def assign_common_attributes(active_enrollment, renewal_enrollment)
      common_attributes = %w(coverage_household_id coverage_kind changing broker_agency_profile_id 
          writing_agent_id original_application_type kind special_enrollment_period_id
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

      benefit_group_assignment = @census_employee.renewal_benefit_group_assignment


      if benefit_group_assignment.blank?
        message = "Unable to find benefit_group_assignment for census_employee: \n"\
          "census_employee: #{@census_employee.full_name} "\
          "id: #{@census_employee.id} "\
          "for hbx_enrollment #{active_enrollment.id}"

        Rails.logger.error { message }
        raise FamilyEnrollmentRenewalFactoryError, message
      end

      renewal_enrollment.benefit_group_assignment_id = benefit_group_assignment.id
      renewal_enrollment.benefit_group_id = benefit_group_assignment.benefit_group_id

      renewal_enrollment.employee_role_id = active_enrollment.employee_role_id
      renewal_enrollment.effective_on = benefit_group_assignment.benefit_group.start_on
      # Set the HbxEnrollment to proper state
      # Renew waiver status
      if active_enrollment.is_coverage_waived? 
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

      # renewal_builder = lambda do |active_enrollment|
      #   renewal_enrollment = @family.active_household.hbx_enrollments.new
      #   renewal_enrollment = assign_common_attributes(active_enrollment, renewal_enrollment)
      #   renewal_enrollment.renew_enrollment
      #   renewal_enrollment
      # end


