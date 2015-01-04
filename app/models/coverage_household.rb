class CoverageHousehold
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :household
  
  field :submitted_at, type: DateTime

  embeds_many :coverage_household_members
  accepts_nested_attributes_for :coverage_household_members

  # include HasApplicants

  def application_group
    return nil unless household
    household.application_group
  end

  def applicant_ids
    coverage_household_members.map(&:applicant_id)
  end

end
