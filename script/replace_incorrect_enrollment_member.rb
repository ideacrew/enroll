#get family and hbx_enrollment with wrong enrollment member
family = Person.where(hbx_id:"19792585").first.primary_family
hbx_enrollment=family.active_household.hbx_enrollments.where(hbx_id:"451575").first

#delete incorrect member
hbx_enrollment.hbx_enrollment_members.select{|em| em.person.hbx_id=="177797"}.first.delete

#add correct member to enrollment
family_member_id = family.active_household.family_members.select{|fm| fm.person.hbx_id=="19873522"}.first.id
hbx_enrollment_new_member = HbxEnrollmentMember.new({
                                                        applicant_id: family_member_id,
                                                        eligibility_date: hbx_enrollment.subscriber.eligibility_date,
                                                        coverage_start_on: hbx_enrollment.subscriber.coverage_start_on
                                                    })
hbx_enrollment.hbx_enrollment_members.push(hbx_enrollment_new_member)
 hbx_enrollment.save!
