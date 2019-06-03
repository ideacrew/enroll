class PlanCostService

  attr_accessor :benefit_group

  def initialize(attrs={})
    @benefit_group = attrs[:benefit_group]
    @reference_plan_id = @benefit_group.reference_plan_id
  end

  def reference_plan
    @reference_plan ||= Plan.find(@reference_plan_id)
  end

  def active_census_employees
  end

  def perform
  end

  def monthly_employer_contribution_amount

    active_census_employees.inject(0.00) do |acc, census_employee|

      per_employee_cost = if census_employee.is_cobra_status?
        0
      else
        (members(census_employee).reduce(0.00) do |sum, member|
          (sum + employer_contribution_for(member, census_employee)).round(2)
        end).round(2)
      end
      BigDecimal.new((acc + per_employee_cost).to_s).round(2)
    end
  end

  def employer_contribution_for(member, census_employee)
    # return 0 if census_employee.is_cobra_status?
    ([max_employer_contribution(member, census_employee), premium_for(member)].min * large_family_factor(member, census_employee)).round(2)
  end

  def premium_for(member)
    # toDo - Handle __getObj__
    if contribution_offered_hash[relationship_for(member)]
      value = rate_lookup(age_of(member), member, census_employee, __getobj__)
      BigDecimal.new("#{value}").round(2).to_f
    else
      0.00
    end
  end

  def max_employer_contribution(member)
    ((large_family_factor(member, census_employee) * reference_premium_for(member, census_employee) * employer_contribution_percent(member)) / 100.00).round(2)
  end

  def employer_contribution_percent(member)
    contribution_pct_hash[relationship_for(member)]
  end

  def contribution_pct_hash
    return @contribution_pct_hash if defined? @contribution_pct_hash
    contribution_hash
    @contribution_pct_hash
  end

  def contribution_offered_hash
    return @contribution_offered_hash if defined? @contribution_offered_hash
    contribution_hash
    @contribution_offered_hash
  end

  def contribution_hash
    return @contribution_hash if defined? @contribution_hash
    benefits = (reference_plan.coverage_kind == 'dental' && benefit_group.dental_reference_plan.present?) ? benfit_group.dental_relationship_benefits : benefit_group.relationship_benefits
    @contribution_pct_hash = benefits.inject({}) do |result, relationship_benefit|
      result[relationship_benefit.relationship] = (relationship_benefit.offered? ? relationship_benefit.premium_pct : 0.0)
      result
    end

    @contribution_offered_hash = benefits.inject({}) do |result, relationship_benefit|
      result[relationship_benefit.relationship] = relationship_benefit.offered?
      result
    end
  end

  def relationship_for(member)
    Rails.cache.fetch("relationship_for_#{member.id}") do
      case member.class
      when SponsoredBenefits::CensusMembers::PlanDesignCensusEmployee
        'employee'
      else
        member.employee_relationship
      end
    end
  end

  def reference_premium_for(member, census_employee)
    reference_plan_member_premium(member, census_employee)
  rescue
    0.00
  end

  def reference_plan_member_premium(member, census_employee)
    rate_lookup(age_of(member), member, census_employee)
  end

  def rate_lookup(age, member, census_employee, the_plan=reference_plan)
    rate_value = if @multiple_rating_areas
      Caches::PlanDetails.lookup_rate_with_area(the_plan.id, start_on, age, benefit_group.rating_area)
    else
      Caches::PlanDetails.lookup_rate(the_plan.id, start_on, age)
    end
    value = if the_plan.health?
      if use_simple_employer_calculation_model?
        1.0
      else
        benefit_group.sic_factor_for(the_plan).to_f * benefit_group.group_size_factor_for(the_plan).to_f
      end
    else
      1.0
    end
    (rate_value * large_family_factor(member, census_employee) * value)
  end

  def large_family_factor(member, census_employee)
    if age_of(member) > 20
      1.00
    else
      if child_index(member, census_employee) > 2 && @plan.health?
        0.00
      else
        1.00
      end
    end
  end

  def child_index(member, census_employee)
    Rails.cache.fetch("census_children_#{census_employee_id}") do
      members(census_employee).select(){|member| age_of(member) < 21}.map(&:id)
    end.index(member.id)
  end

  def age_of(member)
    member.age_on(start_on)
  end

  def members(census_employee)
    Rails.cache.fetch("census_employee_#{census_employee.id}") do
      [census_employee] + census_employee.census_dependents
    end
  end

  def start_on
    @start_on ||= benefit_group.start_on
  end

  def employer_contribution_amount
  end

  def min_employee_cost
  end

  def max_employee_cost
  end

  def benefit_group_costs
  end
end
