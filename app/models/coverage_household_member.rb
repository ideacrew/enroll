class CoverageHouseholdMember
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :coverage_household

  field :applicant_id, type: BSON::ObjectId
  field :is_subscriber, type: Boolean, default: false

  include BelongsToFamilyMember

  def family
    coverage_household.family if coverage_household.present?
  end

  def applicant
    family.family_members.find(applicant_id) if applicant_id.present?
  end

  def is_subscriber?
    self.is_subscriber
  end

end
