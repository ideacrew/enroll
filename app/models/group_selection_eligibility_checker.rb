# This class allows us to check eligibilty for family members.
# It is only a partial fix until we fully correct the group selection page
# to be aware of how composite rating can include/exclude members.
# It does NOT function correctly in the individual market.
class GroupSelectionEligibilityChecker
  MemberAgeSlug = Struct.new(:dob, :member_id)

  def initialize(benefit_package, coverage_kind)
    @sponsored_benefit = benefit_package.sponsored_benefits.detect do |sb|
      sb.product_kind.to_s == coverage_kind.to_s
    end
    @contribution_model = @sponsored_benefit.contribution_model
    @age_calculator = ::BenefitSponsors::CoverageAgeCalculator.new
  end

  def can_cover?(family_member, coverage_date)
    rel, disability, dob = map_family_member_data(family_member)
    return true if (rel.to_s == "self")
    return false if dob > coverage_date
    coverage_age = @age_calculator.calc_coverage_age_for(MemberAgeSlug.new(dob, family_member.id), nil, coverage_date, {}, nil)
    # If the relationship doesn't even map, they aren't allowed
    mapped_relationship = @contribution_model.map_relationship_for(rel, coverage_age, disability)
    return false unless mapped_relationship
    # TODO: Check for mapped relationships that fall under groups that aren't offered
    true
  end

  def map_family_member_data(family_member)
    rel = family_member.is_primary_applicant? ? "self" : family_member.relationship
    disability = family_member.person.is_disabled
    dob = family_member.person.dob
    [rel, disability, dob]
  end
end
