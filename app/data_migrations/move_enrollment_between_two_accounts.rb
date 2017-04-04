require File.join(Rails.root, "lib/mongoid_migration_task")

class MoveEnrollmentBetweenTwoAccount < MongoidMigrationTask
  def migrate
    #find two person accounts and all the hbx_enrollments
    gp = Person.where(hbx_id:ENV['new_account_hbx_id']).first
    bp = Person.where(hbx_id:ENV['old_account_hbx_id']).first
    hbx_enrollments= bp.primary_family.active_household.hbx_enrollments
    #rebuild the family
    #add the family members of the old enrollments to the new enrollment
    family=gp.primary_family
    hbx_enrollments.each do |hbx_enrollment|
      unless hbx_enrollment.hbx_enrollment_members
        hbx_enrollment.hbx_enrollment_members.each do |hbx_enrollment_member|
          family.add_family_member(hbx_enrollment_member.person)
        end
      end
    end
    #move the hbx_enrollments

    hbx_enrollments.each do |hbx_enrollment|
      #check whether the enrollment member of the hbx_enrollment match with each other
      enrollment_person=hbx_enrollment_members.map{|a|a.person}

      if hbx_enrollment.is_shop?
        unless hbx_enrollment.census_employee.nil?
           if hbx_enrollment.census_employee.id == gp.employee_roles.first.census_employee.id


           #   enrollment = HbxEnrollment.new
           #   enrollment.household = coverage_household.household
           #
           #   enrollment.submitted_at = submitted_at
           #   case
           #     when employee_role.present?
           #       if benefit_group.blank? || benefit_group_assignment.blank?
           #         benefit_group, benefit_group_assignment = employee_current_benefit_group(employee_role, enrollment, qle)
           #       end
           #
           #       enrollment.kind = "employer_sponsored"
           #       enrollment.employee_role = employee_role
           #
           #       if qle && enrollment.family.is_under_special_enrollment_period?
           #         enrollment.effective_on = [enrollment.family.current_sep.effective_on, benefit_group.start_on].max
           #         enrollment.enrollment_kind = "special_enrollment"
           #       else
           #         if external_enrollment && coverage_start.present?
           #           enrollment.effective_on = coverage_start
           #         else
           #           enrollment.effective_on = calculate_start_date_from(employee_role, coverage_household, benefit_group)
           #         end
           #         enrollment.enrollment_kind = "open_enrollment"
           #       end
           #
           #       enrollment.benefit_group_id = benefit_group.id
           #       enrollment.benefit_group_assignment_id = benefit_group_assignment.id
           #     when consumer_role.present?
           #       enrollment.consumer_role = consumer_role
           #       enrollment.kind = "individual"
           #       enrollment.benefit_package_id = benefit_package.try(:id)
           #       benefit_sponsorship = HbxProfile.current_hbx.benefit_sponsorship
           #
           #       if qle && enrollment.family.is_under_special_enrollment_period?
           #         enrollment.effective_on = enrollment.family.current_sep.effective_on
           #         enrollment.enrollment_kind = "special_enrollment"
           #       elsif enrollment.family.is_under_ivl_open_enrollment?
           #         enrollment.effective_on = benefit_sponsorship.current_benefit_period.earliest_effective_date
           #         enrollment.enrollment_kind = "open_enrollment"
           #       else
           #         raise "You may not enroll until you're eligible under an enrollment period"
           #       end
           #     when resident_role.present?
           #       enrollment.kind = "coverall"
           #       enrollment.resident_role = resident_role
           #       enrollment.benefit_package_id = benefit_package.try(:id)
           #       benefit_sponsorship = HbxProfile.current_hbx.benefit_sponsorship
           #
           #       if qle && enrollment.family.is_under_special_enrollment_period?
           #         enrollment.effective_on = enrollment.family.current_sep.effective_on
           #         enrollment.enrollment_kind = "special_enrollment"
           #       elsif enrollment.family.is_under_ivl_open_enrollment?
           #         enrollment.effective_on = benefit_sponsorship.current_benefit_period.earliest_effective_date
           #         enrollment.enrollment_kind = "open_enrollment"
           #       else
           #         raise "You may not enroll until you're eligible under an enrollment period"
           #       end
           #     else
           #       raise "either employee_role or consumer_role is required" unless resident_role.present?
           #   end
           #   coverage_household.coverage_household_members.each do |coverage_member|
           #     enrollment_member = HbxEnrollmentMember.new_from(coverage_household_member: coverage_member)
           #     enrollment_member.eligibility_date = enrollment.effective_on
           #     enrollment_member.coverage_start_on = enrollment.effective_on
           #     enrollment.hbx_enrollment_members << enrollment_member
           #   end
           #   enrollment
           # end
           #
           #









             gp.primary_family.active_household.create_hbx_enrollment_from(
                 employee_role: hbx_enrollment.employee_role,
                 consumer_role: hbx_enrollment.consumer_role,
                 coverage_household:gp.primary_family.active_household.immediate_family_coverage_household,
                 benefit_group: hbx_enrollment.benefit_group,
                 benefit_group_assignment:hbx_enrollment.benefit_group_assignment
             )
             bp.primary_family.active_household.delete_hbx_enrollment(hbx_enrollment.id)
           else
             puts "The shop hbx_enrollment #{hbx_enrollment.id} can not moved due to census employee role mismatch"
           end
        else
          puts "The shop hbx_enrollment #{hbx_enrollment.id} can not moved due to no census employee role"
        end
      elsif hbx_enrollment.kind == "individual"
        gp.primary_family.active_household.create_hbx_enrollment_from(

            consumer_role: hbx_enrollment.consumer_role,
            employee_role: hbx_enrollment.employee_role,
            coverage_household:gp.primary_family.active_household.immediate_family_coverage_household
        )
        bp.primary_family.active_household.delete_hbx_enrollment(hbx_enrollment.id)
      else
        puts "Enrollment #{hbx_enrollment.id} can not be moved due to it is neither ivl or shop"
      end
    end
  end
end



