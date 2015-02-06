class CoverageHousehold
  include Mongoid::Document
  include Mongoid::Timestamps
  include HasFamilyMembers

  # The pool of all applicants eligible for enrollment during a certain time period

  embedded_in :household

  field :submitted_at, type: DateTime

  embeds_many :coverage_household_members
  accepts_nested_attributes_for :coverage_household_members

  validate :presence_of_coverage_household_members

  validate :integrity_of_coverage_household_members

  def presence_of_coverage_household_members
    if self.coverage_household_members.size == 0
      self.errors.add(:base, "Should have atleast one coverage_household_member")
    end
  end

  def family
    return nil unless household
    household.family
  end

  def applicant_ids
    coverage_household_members.map(&:applicant_id)
  end

  def integrity_of_coverage_household_members

    return unless family

    return if family.primary_applicant.person.policies.length == 0 #if no policies

    people_in_coverage_household = self.family_members.flat_map(&:person) - [nil]

    enrollees = family.primary_applicant.person.policies.flat_map(&:enrollees).uniq

    people_in_policies = enrollees.map do |enrollee|
      Person.find_by_member_id(enrollee.m_id)
    end

    same_people = people_in_coverage_household.map(&:id).uniq.sort == people_in_policies.map(&:id).uniq.sort

    unless same_people
      self.errors.add(:base, "Applicants in coverage household are not the same as enrollees covered in policies")
    end
  end

end
