require File.join(Rails.root, "lib/mongoid_migration_task")

class MoveEnrollmentBetweenTwoAccount < MongoidMigrationTask
  def migrate
    #find the old and new accounts
    gp = Person.where(hbx_id:ENV['new_account_hbx_id']).first
    bp = Person.where(hbx_id:ENV['old_account_hbx_id']).first

    #find the hbx enrollment to move
    index=-1
    bp.primary_family.active_household.hbx_enrollments.each do |enrollment|

      index = index+1
      if enrollment.hbx_id==ENV['enrollment_hbx_id']
         break
      end
    end
    if index == -1
      raise "No enrollment found"
    else
      hbx1 = bp.primary_family.active_household.hbx_enrollments[index]

      # add the enrollment to the good person
      gp.primary_family.latest_household.update_attributes!(:hbx_enrollments => gp.primary_family.latest_household.hbx_enrollments.append(hbx1))

      #find the family members to be added to the new hbx_enrollments
      if moveable(gp.primary_family,hbx1)
        #move
      else
        #alert(not moveable due to family member not match)
      end

      fm= gp.primary_family.latest_household.hbx_enrollments[0].hbx_enrollment_members.first.family_member
      hbx_total=gp.primary_family.latest_household.hbx_enrollments.size
      gp.primary_family.latest_household.hbx_enrollments[hbx_total-1].hbx_enrollment_members.first.update_attributes!(:family_member => fm)

      #update the consumer role id of the family number
      gp.primary_family.latest_household.hbx_enrollments[hbx_total-1].update_attributes!(:consumer_role_id => gp.consumer_role.id)

      #delete the hbx_enrollment from the old account
      bp.primary_family.latest_household.hbx_enrollments[index]
      bp.primary_family.latest_household.hbx_enrollments.delete_at(index)

       #update the old account's hbx_enrollments
      hbx = bp.primary_family.latest_household.hbx_enrollments
      hh = bp.primary_family.latest_household
      hh.hbx_enrollments = hbx
      hh.save!
    end
  end

  def moveable (family, enrollment)
    binding.pry
    enrollment_ppl_hbx_ids=enrollment.hbx_enrollment_members.map{|a| a.person.hbx_id}
    family_ppl_hbx_ids=family.family_members.map{|a| a.person.hbx_id}
    if enrollment_ppl_hbx_ids.to_set.subset?(family_ppl_hbx_ids.to_set)
      return true
    else
      return false
    end

  end
end
