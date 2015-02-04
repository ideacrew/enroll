module HasFamilyMembers
  def family_members
    return [] unless family
    family.family_members.select { |apl| applicant_ids.include?(apl._id) }
  end

  def people
    family_members.map(&:person)
  end
end
