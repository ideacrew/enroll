class UnassistedPlanCostDecorator < SimpleDelegator
  attr_reader :member_provider
  attr_reader :elected_amount

  def initialize(plan, hbx_enrollment, elected_amount=0)
    super(plan)
    @member_provider = hbx_enrollment
    @elected_amount = elected_amount.to_f
  end

  def members
    member_provider.hbx_enrollment_members
  end

  def plan_year_start_on
    TimeKeeper.date_of_record.beginning_of_year
  end

  def age_of(member)
    member.age_on_effective_date
  end

  def premium_for(member)
    __getobj__.premium_for(plan_year_start_on, age_of(member))
  end

  def employer_contribution_for(member)
    0.0
  end

  # TODO most of ehb from plan are 0.0 or 1 need to confirm that 0 is the correct ehb number
  # Benchmark Plan Cost * APTC share pct
  # Premium Amount * ehb
  def aptc_amount(member)
    if @elected_amount > 0
      [@elected_amount * (premium_for(member) / total_premium), premium_for(member) * ehb].reject{|amount| amount.to_f == 0}.min
    else
      0
    end
  end

  def employee_cost_for(member)
    premium_for(member)
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
    @elected_amount
  end

  def total_employee_cost
    total_premium - total_aptc_amount
  end
end
