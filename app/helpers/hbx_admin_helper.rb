module HbxAdminHelper

  def full_name_of_person(person_id)
    Person.find(person_id).full_name
  end

  def ehb_percent_for_enrrollment(hbx_id)
  	ehb = HbxEnrollment.find(hbx_id).plan.ehb
  	enb_percent = (ehb*100).round(2)
  end
  
  def max_aptc_that_can_be_applied_for_this_enrollment(hbx_id, max_aptc_for_household)
  	#1 Get all members in the enrollment
  	#2 Get APTC ratio for each of these members
  	#3 Max APTC for Enrollment => Sum all (ratio * max_aptc) for each members
  	max_aptc_for_enrollment = 0
  	hbx = HbxEnrollment.find(hbx_id)
  	hbx_enrollment_members = hbx.hbx_enrollment_members
  	aptc_ratio_by_member = hbx.family.active_household.latest_active_tax_household.aptc_ratio_by_member
  	hbx_enrollment_members.each do |hem|
    	max_aptc_for_enrollment += (aptc_ratio_by_member[hem.applicant_id.to_s] * max_aptc_for_household)
  	end
  	if max_aptc_for_enrollment > max_aptc_for_household
  		max_aptc_for_household
  	else
  		max_aptc_for_enrollment
  	end
  end

end
