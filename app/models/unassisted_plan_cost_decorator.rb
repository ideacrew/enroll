class UnassistedPlanCostDecorator < SimpleDelegator
  attr_reader :member_provider
  attr_reader :elected_aptc
  attr_reader :tax_household

  def initialize(plan, hbx_enrollment, elected_aptc=0, tax_household=nil)
    super(plan)
    @member_provider = hbx_enrollment
    @elected_aptc = elected_aptc.to_f
    @tax_household = tax_household
  end

  def members
    member_provider.hbx_enrollment_members
  end

  def schedule_date
    @member_provider.effective_on
  end

  def age_of(member)
    member.age_on_effective_date
  end

  def child_index(member)
    @children = members.select(){|member| relationship_for(member) == "child_under_26" && age_of(member) < 21} unless defined?(@children)
    @children.index(member) || -1
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

  def relationship_for(member)
    case member.class
    when HbxEnrollmentMember
      if member.is_subscriber?
        "employee"
      else
        benefit_relationship(member.primary_relationship)
      end
    else
      member.employee_relationship
    end
  end

  def large_family_factor(member)
    if age_of(member) > 20
      1.0
    else
      if child_index(member) > 2
        0.0
      else
        1.0
      end
    end
  end

  def premium_for(member)
    Caches::PlanDetails.lookup_rate(__getobj__.id, schedule_date, age_of(member)) * large_family_factor(member)
  end

  def employer_contribution_for(member)
    0.0
  end

  def aptc_amount(member)
    if @tax_household.present?
      aptc_available_hash = @tax_household.aptc_available_amount_for_enrollment(@member_provider, __getobj__, @elected_aptc)
      (aptc_available_hash[member.applicant_id.to_s].try(:to_f) || 0) * large_family_factor(member)
    else
      0
    end
  end

  def employee_cost_for(member)
    cost = premium_for(member) - aptc_amount(member)
    cost = 0 if cost < 0
    cost * large_family_factor(member)
  end

  def total_premium
    members.reduce(0) do |sum, member|
      sum + premium_for(member)
    end
  end

  def total_employer_contribution
    0.0
  end

  def total_aptc_amount
    members.reduce(0) do |sum, member|
      sum + aptc_amount(member)
    end
  end

  def total_employee_cost
    members.reduce(0) do |sum, member|
      sum + employee_cost_for(member)
    end
  end
end
