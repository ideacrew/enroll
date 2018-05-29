# This class allows us to check eligibilty for family members.
# It is only a partial fix until we fully correct the group selection page
# to be aware of how composite rating can include/exclude members.
# It does NOT function correctly in the individual market.
class GroupSelectionEligibilityChecker

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
    coverage_age = calc_coverage_age_for(member, nil, coverage_date, {}, nil)
    mapped_relationship = @contribution_model.map_relationship_for(relationship, coverage_age, disability)
    return false unless mapped_relationship
    # FIXME:
    # Correct checking for relationship coverage in model once I can add family members again
    true
  end

  def map_family_member_data(family_member)
    rel = family_member.is_primary_applicant? ? "self" : family_member.relationship
    disability = family_member.is_disabled?
    dob = family_member.person.dob
    [rel, disability, dob]
  end
end
