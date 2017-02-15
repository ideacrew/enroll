require File.join(Rails.root, "lib/mongoid_migration_task")

class MoveEnrollmentBetweenTwoAccount < MongoidMigrationTask
  def migrate
    gp = Person.where(hbx_id:ENV['new_account_hbx_id']).first
    bp = Person.where(hbx_id:ENV['old_account_hbx_id']).first
    enroll_hbx_id=ENV['enrollment_hbx_id']
    if  bp.primary_family.active_household.hbx_enrollments.where(hbx_id:enroll_hbx_id).first
      hbx1 = bp.primary_family.active_household.hbx_enrollments.where(hbx_id:enroll_hbx_id).first
    else
      raise "No enrollment found"
    end
    move_index=moveable(gp.primary_family,hbx1)
    unless move_index
      gp.primary_family.latest_household.update_attributes!(:hbx_enrollments => gp.primary_family.latest_household.hbx_enrollments.append(hbx1))
      fm= gp.primary_family.latest_household.hbx_enrollments[0].hbx_enrollment_members.first.family_member
      hbx_total=gp.primary_family.latest_household.hbx_enrollments.size
      gp.primary_family.latest_household.hbx_enrollments[hbx_total-1].hbx_enrollment_members.each do |m|
        m.update_attributes!(:family_member => fm)
      end
      gp.primary_family.latest_household.hbx_enrollments[hbx_total-1].update_attributes!(:consumer_role_id => gp.consumer_role.id)
      bp.primary_family.latest_household.hbx_enrollments.delete_at(index)
      hbx = bp.primary_family.latest_household.hbx_enrollments
      hh = bp.primary_family.latest_household
      hh.hbx_enrollments = hbx
      hh.save!
    end
  end


  def moveable (family, enrollment)
    enrollment_ppl_hbx_ids=enrollment.try(:hbx_enrollment_members).map{|a| a.person.hbx_id}
    family_ppl_hbx_ids=family.family_members.map{|a| a.person.hbx_id}
    if enrollment_ppl_hbx_ids.to_set.subset?(family_ppl_hbx_ids.to_set)
      return true
    else
      return false
    end

  end
end
