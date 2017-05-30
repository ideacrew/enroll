module Factories
  class FamilyEnrollmentRenewalFactory
    include Mongoid::Document

    # Renews a family's active enrollments from current plan year
    attr_accessor :family, :census_employee, :employer, :renewing_plan_year, :enrollment, :disable_notifications

    def initialize
      @disable_notifications = false
    end

    def renew_enrollment(enrollment: nil, waiver: false)
      ShopEnrollmentRenewalFactory.new({
        family: family, 
        census_employee: census_employee, 
        employer: employer, 
        renewing_plan_year: renewing_plan_year, 
        enrollment: enrollment,
        is_waiver: waiver
      }).renew_coverage
    end

    def find_active_coverage(coverage_kind)
      active_plan_year = employer.plan_years.published_plan_years_by_date(renewing_plan_year.start_on.prev_day).first
      bg_ids = active_plan_year.benefit_groups.pluck(:_id)

      shop_enrollments = family.active_household.hbx_enrollments.shop_market.enrolled_and_waived.by_coverage_kind(coverage_kind)
      shop_enrollments = shop_enrollments.where(:benefit_group_id.in => bg_ids, :aasm_state.ne => 'coverage_termination_pending')

      shop_enrollments.compact.sort_by{|e| e.submitted_at || e.created_at }.last
    end

    def renew
      raise ArgumentError unless defined?(family)

      HbxEnrollment::COVERAGE_KINDS.each do |coverage_kind|
        active_enrollment = find_active_coverage(coverage_kind)

        begin
          if active_enrollment.present?

            renewal_enrollments = family.active_household.hbx_enrollments.by_coverage_kind(coverage_kind).where({
              :benefit_group_id.in => renewing_plan_year.benefit_groups.pluck(:_id)
              })

            passive_renewals = renewal_enrollments.renewing
            active_renewals = renewal_enrollments.enrolled_and_waived

            if active_renewals.present?
              passive_renewals.each{|e| e.cancel_coverage! if e.may_cancel_coverage?}
              next
            end

            if passive_renewals.blank?
              if active_enrollment.present? && active_enrollment.inactive?
                renew_enrollment(enrollment: active_enrollment, waiver: true)
                trigger_notice { "employee_open_enrollment_unenrolled" }
              elsif renewal_plan_offered_by_er?(active_enrollment)
                renew_enrollment(enrollment: active_enrollment)
                trigger_notice { "employee_open_enrollment_auto_renewal" }
              else
                renew_enrollment(enrollment: nil, waiver: true)
                trigger_notice { "employee_open_enrollment_no_auto_renewal" }
              end
            end
          elsif family.active_household.hbx_enrollments.where(:aasm_state => 'renewing_waived').blank?
            renew_enrollment(enrollment: nil, waiver: true)
            trigger_notice { "employee_open_enrollment_unenrolled" }
          end
        rescue Exception => e
          puts "Error found for #{census_employee.full_name} while creating renewals -- #{e.inspect}" unless Rails.env.test?
        end
      end

      family
    end

    def trigger_notice
      if !disable_notifications
        ShopNoticesNotifierJob.perform_later(census_employee.id.to_s, yield)
      end
    end

    def renewal_plan_offered_by_er?(enrollment)
      if enrollment.plan.present? || enrollment.plan.renewal_plan.present?
        if @census_employee.renewal_benefit_group_assignment.blank?
          benefit_group = renewing_plan_year.default_benefit_group || renewing_plan_year.benefit_groups.first
          @census_employee.add_renew_benefit_group_assignment(benefit_group)
          @census_employee.save!
        end
        
        benefit_group = @census_employee.renewal_benefit_group_assignment.benefit_group
        elected_plan_ids = (enrollment.coverage_kind == 'health' ? benefit_group.elected_plan_ids : benefit_group.elected_dental_plan_ids)
        elected_plan_ids.include?(enrollment.plan.renewal_plan_id)
      else
        false
      end
    end

    # def renew_waived_enrollment(waived_enrollment = nil)
    #   renewal_enrollment = family.active_household.hbx_enrollments.new

    #   renewal_enrollment.coverage_kind = "health"
    #   renewal_enrollment.enrollment_kind = "open_enrollment"
    #   renewal_enrollment.kind = "employer_sponsored"

    #   if @census_employee.renewal_benefit_group_assignment.blank?
    #     @census_employee.add_renew_benefit_group_assignment(@renewing_plan_year.benefit_groups.first)
    #   end

    #   benefit_group_assignment = @census_employee.renewal_benefit_group_assignment

    #   benefit_group_assignment = @census_employee.renewal_benefit_group_assignment
    #   if benefit_group_assignment.blank?
    #     message = "Unable to find benefit_group_assignment for census_employee: \n"\
    #       "census_employee: #{@census_employee.full_name} "\
    #       "id: #{@census_employee.id} "

    #     Rails.logger.error { message }
    #     raise FamilyEnrollmentRenewalFactoryError, message
    #   end

    #   renewal_enrollment.benefit_group_assignment_id = benefit_group_assignment.id
    #   renewal_enrollment.benefit_group_id = benefit_group_assignment.benefit_group_id
    #   renewal_enrollment.effective_on = benefit_group_assignment.benefit_group.start_on

    #   renewal_enrollment.waiver_reason = waived_enrollment.try(:waiver_reason) || "I do not have other coverage"
    #   renewal_enrollment.renew_waived
    #   renewal_enrollment.submitted_at = TimeKeeper.datetime_of_record

    #   if renewal_enrollment.save
    #     return
    #   else
    #     message = "Unable to save waived renewal enrollment: #{renewal_enrollment.inspect}, \n" \
    #       "Error(s): \n #{renewal_enrollment.errors.map{|k,v| "#{k} = #{v}"}.join(" & \n")} \n"

    #       Rails.logger.error { message }

    #     raise FamilyEnrollmentRenewalFactoryError, message
    #   end
    # end

    # def renewal_builder(active_enrollment)
    #   renewal_enrollment = family.active_household.hbx_enrollments.new
    #   renewal_enrollment = assign_common_attributes(active_enrollment, renewal_enrollment)
    #   renewal_enrollment.renew_enrollment
    #   renewal_enrollment
    # end


    # # def display_premiums(enrollment)
    # #   puts "#{enrollment.aasm_state.humanize} enrollment amounts-------"
    # #   puts enrollment.total_premium
    # #   puts enrollment.total_employer_contribution
    # #   puts enrollment.total_employee_cost
    # #   puts "member premiums #{enrollment.hbx_enrollment_members.map(&:premium_amount)}"
    # #   puts "---------------------------------"
    # # end

    # def save_renewal_enrollment(renewal_enrollment, active_enrollment)
    #   if renewal_enrollment.save
    #     renewal_enrollment
    #   else
    #     message = "Enrollment: #{active_enrollment.id}, \n" \
    #     "Unable to save renewal enrollment: #{renewal_enrollment.inspect}, \n" \
    #       "Error(s): \n #{renewal_enrollment.errors.map{|k,v| "#{k} = #{v}"}.join(" & \n")} \n"

    #     Rails.logger.error { message }
    #     raise FamilyEnrollmentRenewalFactoryError, message
    #   end
    # end

    # def assign_common_attributes(active_enrollment, renewal_enrollment)
    #   common_attributes = %w(coverage_household_id coverage_kind changing broker_agency_profile_id
    #       writing_agent_id original_application_type kind special_enrollment_period_id
    #     )
    #   common_attributes.each do |attr|
    #      renewal_enrollment.send("#{attr}=", active_enrollment.send(attr))
    #   end

    #   renewal_enrollment.plan_id = active_enrollment.plan.renewal_plan_id if active_enrollment.plan.present?
    #   renewal_enrollment
    # end

    # def clone_ivl_enrollment
    #   # consumer_role_id
    #   # elected_amount
    #   # elected_premium_credit
    #   # applied_premium_credit
    #   # elected_aptc_amount
    #   # applied_aptc_amount

    #   # renewal_enrollment.renew_coverage
    # end

    # def clone_shop_enrollment(active_enrollment, renewal_enrollment)
    #   # Find and associate with new ER benefit group

    #   if @census_employee.renewal_benefit_group_assignment.blank?
    #     @census_employee.add_renew_benefit_group_assignment(@renewing_plan_year.benefit_groups.first)
    #   end

    #   benefit_group_assignment = @census_employee.renewal_benefit_group_assignment

    #   if benefit_group_assignment.blank?
    #     message = "Unable to find benefit_group_assignment for census_employee: \n"\
    #       "census_employee: #{@census_employee.full_name} "\
    #       "id: #{@census_employee.id} "\
    #       "for hbx_enrollment #{active_enrollment.id}"

    #     Rails.logger.error { message }
    #     raise FamilyEnrollmentRenewalFactoryError, message
    #   end

    #   renewal_enrollment.benefit_group_assignment_id = benefit_group_assignment.id
    #   renewal_enrollment.benefit_group_id = benefit_group_assignment.benefit_group_id

    #   renewal_enrollment.employee_role_id = active_enrollment.employee_role_id
    #   renewal_enrollment.effective_on = benefit_group_assignment.benefit_group.start_on
    #   renewal_enrollment.kind = active_enrollment.kind if active_enrollment.is_cobra_status?
    #   # Set the HbxEnrollment to proper state

    #   # Renew waiver status
    #   if active_enrollment.is_coverage_waived?
    #     renewal_enrollment.waiver_reason = active_enrollment.waiver_reason
    #     renewal_enrollment.waive_coverage
    #   end

    #   renewal_enrollment.hbx_enrollment_members = clone_enrollment_members(active_enrollment, renewal_enrollment)
    #   renewal_enrollment
    # end

    # # clone enrollment members if relationship offered in renewal plan year and active in current hbxenrollment
    def clone_enrollment_members(active_enrollment, renewal_enrollment)
      hbx_enrollment_members = active_enrollment.hbx_enrollment_members
      hbx_enrollment_members.reject!{|member| !is_relationship_offered_and_member_covered?(member,renewal_enrollment) }
      hbx_enrollment_members.inject([]) do |members, hbx_enrollment_member|
        members << HbxEnrollmentMember.new({
          applicant_id: hbx_enrollment_member.applicant_id,
          eligibility_date: @plan_year_start_on,
          coverage_start_on: @plan_year_start_on,
          is_subscriber: hbx_enrollment_member.is_subscriber
        })
      end
    end

    # # relationship_benefits of renewal plan year
    def renewal_relationship_benefits(renewal_enrollment)
      benefit_group = @census_employee.renewal_benefit_group_assignment.benefit_group
      if renewal_enrollment.coverage_kind == "health"
        benefit_group.relationship_benefits.select(&:offered).map(&:relationship)
      else
        benefit_group.dental_relationship_benefits.select(&:offered).map(&:relationship)
      end
    end

    # # relationship offered in renewal plan year and member active in enrollment.
    def is_relationship_offered_and_member_covered?(member,renewal_enrollment)
      relationship = PlanCostDecorator.benefit_relationship(member.primary_relationship)
      relationship = "child_over_26" if relationship == "child_under_26" && member.person.age_on(@plan_year_start_on) >= 26
      (renewal_relationship_benefits(renewal_enrollment).include?(relationship) && member.is_covered_on?(@plan_year_start_on - 1.day))
    end

    # # Validate enrollment membership against benefit package-covered relationships
    # def family_eligibility(active_enrollment, renewal_enrollment)
    #   coverage_household.coverage_household_members.each do |coverage_member|
    #     enrollment_member = HbxEnrollmentMember.new_from(coverage_household_member: coverage_member)
    #     enrollment_member.eligibility_date = enrollment.effective_on
    #     enrollment_member.coverage_start_on = enrollment.effective_on
    #     renewal_enrollment.hbx_enrollment_members << enrollment_member
    #   end

    #   renewal_enrollment.hbx_enrollment_members
    # end

    # def set_instance_variables
    #   @family = enrollment.family

    #   if enrollment.employee_role.present?
    #     @census_employee = enrollment.employee_role.census_employee
    #   elsif enrollment.benefit_group_assignment.present?
    #     @census_employee = enrollment.benefit_group_assignment.census_employee
    #   end

    #   if @census_employee.present?
    #     @employer = @census_employee.employer_profile 
    #     @renewing_plan_year = @employer.renewing_published_plan_year
    #   end
    # end
  end

  class FamilyEnrollmentRenewalFactoryError < StandardError; end
end


