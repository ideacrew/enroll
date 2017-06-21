class CompositeRatedPlanCostDecorator < SimpleDelegator
  def initialize(plan, benefit_group, composite_rating_tier)
    super(plan)
    @plan = plan
    @benefit_group = benefit_group
    @composite_rating_tier = composite_rating_tier
  end

  def employer_contribution_for(member)
    0.00
  end

  def employee_cost_for(member)
    0.00
  end

  def total_premium
    @benefit_group.composite_rating_tier_premium_for(@composite_rating_tier)
  end

  def total_employer_contribution
    (total_premium * employer_contribution_factor).round(2)
  end

  def total_employee_cost
    (total_premium - total_employer_contribution).round(2)
  end

  def premium_for(_member)
    0.00
  end

  def employer_contribution_factor
    @benefit_group.composite_employer_contribution_factor_for(@composite_rating_tier)
  end
end
