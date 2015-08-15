class PlanCostDecorator < SimpleDelegator
  attr_reader :member_provider, :benefit_group, :reference_plan

  def initialize(plan, member_provider, benefit_group, reference_plan)
    super(plan)
    @member_provider = member_provider
    @benefit_group = benefit_group
    @reference_plan = reference_plan
  end

  def members
    case member_provider.class
    when HbxEnrollment
      member_provider.hbx_enrollment_members
    when CensusEmployee
      [member_provider] + member_provider.census_dependents
    end
  end

  def plan_year_start_on
    #FIXME only for temp ivl
    if @benefit_group.present?
      benefit_group.plan_year.start_on
    else
      TimeKeeper.date_of_record.beginning_of_year
    end
  end

  def age_of(member)
    case member.class
    when HbxEnrollmentMember
      member.age_on_effective_date
    else
      member.age_on(plan_year_start_on)
    end
  end

  def benefit_relationship(person_relationship)
    PlanCostDecorator.benefit_relationship(person_relationship)
  end

  def self.benefit_relationship(person_relationship)
    {
      "head of household" => nil,
      "spouse" => "spouse",
      "ex-spouse" => "spouse",
      "cousin" => nil,
      "ward" => "child_under_26",
      "trustee" => "child_under_26",
      "annuitant" => nil,
      "other relationship" => nil,
      "other relative" => nil,
      "self" => "employee",
      "parent" => nil,
      "grandparent" => nil,
      "aunt_or_uncle" => nil,
      "nephew_or_niece" => nil,
      "father_or_mother_in_law" => nil,
      "daughter_or_son_in_law" => nil,
      "brother_or_sister_in_law" => nil,
      "adopted_child" => "child_under_26",
      "stepparent" => nil,
      "foster_child" => "child_under_26",
      "sibling" => nil,
      "stepchild" => "child_under_26",
      "sponsored_dependent" => "child_under_26",
      "dependent_of_a_minor_dependent" => nil,
      "guardian" => nil,
      "court_appointed_guardian" => nil,
      "collateral_dependent" => "child_under_26",
      "life_partner" => "domestic_partner",
      "child" => "child_under_26",
      "grandchild" => nil,
      "unrelated" => nil,
      "great_grandparent" => nil,
      "great_grandchild" => nil,
    }[person_relationship]
  end

  def relationship(member)
    if member.is_subscriber?
      "employee"
    else
      benefit_relationship(member.primary_relationship)
    end
  end


  def relationship_benefit_for(member)
    relationship =
    case member.class
    when HbxEnrollmentMember
      (relationship(member))
    else
      member.employee_relationship
    end
    benefit_group.relationship_benefit_for(relationship)
  end

  def employer_contribution_percent(member)
    relationship_benefit = relationship_benefit_for(member)
    if relationship_benefit && relationship_benefit.offered?
      relationship_benefit.premium_pct
    else
      0.0
    end
  end

  def reference_premium_for(member)
    reference_plan.premium_for(plan_year_start_on, age_of(member))
  end

  def premium_for(member)
    relationship_benefit = relationship_benefit_for(member)
    if relationship_benefit && relationship_benefit.offered?
      __getobj__.premium_for(plan_year_start_on, age_of(member))
    else
      0.0
    end
  end

  def max_employer_contribution(member)
    (reference_premium_for(member) * employer_contribution_percent(member)) / 100.00
  end

  def employer_contribution_for(member)
    [max_employer_contribution(member), premium_for(member)].min
  end

  def employee_cost_for(member)
    if @benefit_group.present?
      premium_for(member) - employer_contribution_for(member)
    else
      __getobj__.premium_for(plan_year_start_on, age_of(member))
    end
  end

  def total_premium
    members.reduce(0) do |sum, member|
      sum + premium_for(member)
    end
  end

  def total_employer_contribution
    members.reduce(0) do |sum, member|
      sum + employer_contribution_for(member)
    end
  end

  def total_employee_cost
    members.reduce(0) do |sum, member|
      sum + employee_cost_for(member)
    end
  end
end
