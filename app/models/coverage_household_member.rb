class CoverageHouseholdMember
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :coverage_household

  field :family_member_id, type: BSON::ObjectId
  field :applicant_id, type: BSON::ObjectId
  field :is_subscriber, type: Boolean, default: false

  include BelongsToFamilyMember

  def family
    coverage_household.household.family
  end

  def family_member=(new_family_member)
    if coverage_household && (coverage_household.coverage_household_members.where(family_member_id: new_family_member._id) == [])
      self.family_member_id = new_family_member._id
    end
  end

  def family_member
    family.family_members.find(family_member_id) if family_member_id.present?
  end

  def applicant=(new_applicant)
    family_member = new_applicant
  end

  def applicant
    family_member
  end

  def is_subscriber?
    self.is_subscriber
  end

end
