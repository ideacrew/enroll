class CoverageHouseholdMember
  include Mongoid::Document
  include Mongoid::Timestamps
  include Acapi::Notifiers

  embedded_in :coverage_household

  field :family_member_id, type: BSON::ObjectId
  field :is_subscriber, type: Boolean, default: false

  # def save_parent
  #   coverage_household.save
  # end

  include BelongsToFamilyMember

  def family
    coverage_household.household.family
  end

  def family_member=(new_family_member)
    self.family_member_id = new_family_member._id
    @family_member = new_family_member
  end

  def family_member
    return @family_member if defined? @family_member
    target_family_member = family.family_members.detect { |fm| fm.id.to_s == family_member_id.to_s }
    # For targeting family members not present but the ID is being passed through in
    # app/views/insured/group_selection/_coverage_household.html.erb
    # @coverage_household.valid_coverage_household_members.map(&:family_member).each_with_index
    if target_family_member.blank?
      error_message = "No family member present for family with id #{family_member_id} for family with mongo ID #{family.id}"
      log(error_message)
    end

    @family_member = target_family_member
  end

  def applicant=(new_applicant)
    @applicant = new_applicant
  end

  def applicant
    return @applicant if defined? @applicant
    @applicant = family_member
  end

  def is_subscriber?
    self.is_subscriber
  end

end
