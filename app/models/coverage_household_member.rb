class CoverageHouseholdMember
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :coverage_household

  field :applicant_id, type: Moped::BSON::ObjectId
  field :is_subscriber, type: Boolean, default: false

  include BelongsToFamilyMember

  def family
    return nil unless coverage_household
    coverage_household.family
  end

  def is_subscriber?
    self.is_subscriber
  end

end
