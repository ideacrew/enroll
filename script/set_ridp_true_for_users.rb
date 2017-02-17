
def curam_user?(person)
  person.primary_family.e_case_id.present? && !(family.e_case_id.include? "curam_landing")
end

def user_prior_to_enroll?(person)
  if person.primary_family.present? && person.primary_family.active_household.present?
    person.primary_family.active_household.hbx_enrollments.where(kind: 'individual').present?
  end
end

def consumer_role_boomarked?(person)
  person.consumer_role.bookmark_url == "/families/home"
end


Person.all_consumer_roles.each do |person|
  begin
    if person.user && !person.user.identity_verified?
      if curam_user?(person) || user_prior_to_enroll?(person) || consumer_role_boomarked?(person)
        person.user.update_attributes(:identity_final_decision_code => USER::INTERACTIVE_IDENTITY_VERIFICATION_SUCCESS_CODE)
      end
    end
  rescue
    puts "Bad person record #{person.id}"
  end
end



# count = 0
# Person.all_consumer_roles.each do |person|
#   if person.user.present? && !person.user.identity_verified? && person.primary_family.present? && person.primary_family.e_case_id.blank?
#     if person.consumer_role.bookmark_url == "/families/home" && person.primary_family.active_household.present? && person.primary_family.active_household.hbx_enrollments.present?
#       count = count + 1
#     end
#   end
# end

