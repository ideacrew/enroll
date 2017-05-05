require File.join(Rails.root, "lib/mongoid_migration_task")

class MoveEnrollmentBetweenTwoAccount < MongoidMigrationTask
  def migrate
    #find two person accounts and all the hbx_enrollments
    new_account_hbx_id = ENV['new_account_hbx_id']
    old_account_hbx_id = ENV['old_account_hbx_id']
    gp = Person.where(hbx_id:new_account_hbx_id).first
    bp = Person.where(hbx_id:old_account_hbx_id).first
    if gp.nil?
      puts "No person record was found with given hbx_id #{new_account_hbx_id}" unless Rails.env.test?
    elsif bp.nil?
      puts "No person record was found with given hbx_id #{old_account_hbx_id}" unless Rails.env.test?
    else
      enrollment_hbx_id = HbxEnrollment.by_hbx_id(ENV['enrollment_hbx_id'])
      hbx_enrollment= bp.primary_family.active_household.hbx_enrollments.where(hbx_id:enrollment_hbx_id).first
      if hbx_enrollment.nil?
        puts "No hbx_enrollment was found with given hbx_id #{enrollment_hbx_id}" unless Rails.env.test?
      elsif !check_family_member_match(bp.primary_family,gp.primary_family)
        puts "The enrollment with hbx_id #{enrollment_hbx_id} can not be moved due to a mismatch of family members" unless Rails.env.test?
      else
        if hbx_enrollment.is_shop?
          #1 check whether moveable
          #2create the new hbx_enrollment
          #3delete the old hbx_enrollment
          if gp.employee_roles.empty? ||  bp.employee_roles.empty?
            puts "The shop hbx_enrollment #{hbx_enrollment.id} can not moved due to two people dont linked to employee.role " unless Rails.env.test?
          else
            good_employer=gp.employee_roles.first.census_employee.employer_profile.first
            bad_employer=bp.employee_roles.first.census_employee.employer_profile.first
            if good_employer || bad_employer || good_employer.id != bad_employer.id
              puts "The shop hbx_enrollment #{hbx_enrollment.id} can not moved due to two people dont linked to the same employer" unless Rails.env.test?
            elsif good_employer.active_plan_year.benefit_groups.map{|a| a.id}.include? hbx_enrollment.benefit_group.id
              #create the new hbx_enrollment
              gp.primary_family.active_household.create_hbx_enrollment_from(
                  employee_role: hbx_enrollment.employee_role,
                  consumer_role: hbx_enrollment.consumer_role,
                  coverage_household:gp.primary_family.active_household.immediate_family_coverage_household,
                  benefit_group: hbx_enrollment.benefit_group,
                  benefit_group_assignment:hbx_enrollment.benefit_group_assignment
              )
              bp.primary_family.active_household.delete_hbx_enrollment(hbx_enrollment.id)
            else
              puts "The shop hbx_enrollment #{hbx_enrollment.id} can not moved due to a mismatch of benegit groups" unless Rails.env.test?
            end

          end
       elsif hbx_enrollment.kind == "individual"
          #1 check whether moveable
          if gp.consumer_role.present? && bp.consumer_role.present?
            #2create the new hbx_enrollment
            #? how to add enrollment member
            #3delete the old hbx_enrollment
            gp.primary_family.active_household.create_hbx_enrollment_from(
                consumer_role: hbx_enrollment.consumer_role,
                employee_role: hbx_enrollment.employee_role,
                coverage_household:gp.primary_family.active_household.immediate_family_coverage_household
            )
            bp.primary_family.active_household.delete_hbx_enrollment(hbx_enrollment.id)

          else
            puts "the enrollment can not be moved due to at least one of the person has no consumer role" unless Rails.env.test?
          end
        else
          puts "Enrollment #{hbx_enrollment.id} can not be moved due to it is neither ivl or shop" unless Rails.env.test?
        end
      end
    end
end
  def check_family_member_match(family_from,family_to)
  #if family_to's family members include all family_from's family members, return true
    return true if family_from.id == family_to.id
    family_from_members = family_from.family_members.to_a
    family_to_members = family_to.family_members.to_a
    return true if family_from_members == family_to_members
    return true if (family_to_members-family_from_members).empty? == false
    return false
  end
end


