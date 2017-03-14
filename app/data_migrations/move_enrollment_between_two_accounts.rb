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
      if hbx_enrollment.is_shop?
        unless hbx_enrollment.census_employee.nil?
           if hbx_enrollment.census_employee.id == gp.employee_roles.first.census_employee.id
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







#
#
#
#     enroll_hbx_id=ENV['enrollment_hbx_id']
#     if  bp.primary_family.active_household.hbx_enrollments.where(hbx_id:enroll_hbx_id).first
#       hbx1 = bp.primary_family.active_household.hbx_enrollments.where(hbx_id:enroll_hbx_id).first
#     else
#       raise "No enrollment found"
#     end
#     move_index=moveable(gp.primary_family,hbx1)
#     unless move_index
#       gp.primary_family.latest_household.update_attributes!(:hbx_enrollments => gp.primary_family.latest_household.hbx_enrollments.append(hbx1))
#       fm= gp.primary_family.latest_household.hbx_enrollments[0].hbx_enrollment_members.first.family_member
#       hbx_total=gp.primary_family.latest_household.hbx_enrollments.size
#       gp.primary_family.latest_household.hbx_enrollments[hbx_total-1].hbx_enrollment_members.each do |m|
#         m.update_attributes!(:family_member => fm)
#       end
#       gp.primary_family.latest_household.hbx_enrollments[hbx_total-1].update_attributes!(:consumer_role_id => gp.consumer_role.id)
#       bp.primary_family.latest_household.hbx_enrollments.delete_at(index)
#       hbx = bp.primary_family.latest_household.hbx_enrollments
#       hh = bp.primary_family.latest_household
#       hh.hbx_enrollments = hbx
#       hh.save!
#     end
#   end
#
#
#   def moveable (family, enrollment)
#     enrollment_ppl_hbx_ids=enrollment.try(:hbx_enrollment_members).map{|a| a.person.hbx_id}
#     family_ppl_hbx_ids=family.family_members.map{|a| a.person.hbx_id}
#     if enrollment_ppl_hbx_ids.to_set.subset?(family_ppl_hbx_ids.to_set)
#       return true
#     else
#       return false
#     end
#
#   end
# end
