class PlanCostDecorator < SimpleDelegator
  attr_reader :hbx_enrollment, :benefit_group, :reference_plan

  def initialize(plan, hbx_enrollment, benefit_group, reference_plan)
    super(plan)
    @hbx_enrollment = hbx_enrollment
    @benefit_group = benefit_group
    @reference_plan = reference_plan
  end

  def hbx_enrollment_member
    hbx_enrollment.hbx_enrollment_members
  end

  def plan_year_start_on
    benefit_group.plan_year.start_on
  end

  def age_of(member)
    member.age_on_effective_date
  end

  def relationship(member)
    # TODO: commented implementation returns relationships that do not match relationship_benefit relationships
    # member.family.primary_applicant.find_relationship_with(member.family_member)
    "employee"
  end

  def employer_contribution_percent(member)
    benefit_group.relationship_benefit_for(relationship(member)).premium_pct
  end

  def reference_premium_for(member)
    reference_plan.premium_for(plan_year_start_on, age_of(member))
  end

  def premium_for(member)
    __getobj__.premium_for(plan_year_start_on, age_of(member))
  end

  def max_employer_contribution(member)
    (reference_premium_for(member) * employer_contribution_percent(member)) / 100.00
  end

  def employer_contribution_for(member)
    [max_employer_contribution(member), premium_for(member)].min
  end

  def employee_cost_for(member)
    premium_for(member) - employer_contribution_for(member)
  end

  def total_premium
    hbx_enrollment.hbx_enrollment_members.reduce(0) do |sum, member|
      sum + premium_for(member)
    end
  end

  def total_employer_contribution
    hbx_enrollment.hbx_enrollment_members.reduce(0) do |sum, member|
      sum + employer_contribution_for(member)
    end
  end

  def total_employee_cost
    hbx_enrollment.hbx_enrollment_members.reduce(0) do |sum, member|
      sum + employee_cost_for(member)
    end
  end
end
