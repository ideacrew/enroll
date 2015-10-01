class UnassistedPlanCostDecorator < SimpleDelegator
  attr_reader :member_provider
  attr_reader :elected_pct
  attr_reader :tax_household

  def initialize(plan, hbx_enrollment, elected_pct=0, tax_household=nil)
    super(plan)
    @member_provider = hbx_enrollment
    @elected_pct = elected_pct.to_f
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

  def premium_for(member)
    __getobj__.premium_for(schedule_date, age_of(member)) rescue 0
  end

  def employer_contribution_for(member)
    0.0
  end

  def aptc_amount(member)
    if @tax_household.present?
      aptc_available_hash = @tax_household.aptc_available_amount_for_enrollment(@member_provider, __getobj__, @elected_pct)
      aptc_available_hash[member.applicant_id.to_s].try(:to_f) || 0
    else
      0
    end
  end

  def employee_cost_for(member)
    cost = premium_for(member) - aptc_amount(member)
    cost = 0 if cost < 0
    cost
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
