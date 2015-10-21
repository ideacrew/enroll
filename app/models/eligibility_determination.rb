class EligibilityDetermination
  include Mongoid::Document
  include SetCurrentUser
  include Mongoid::Timestamps

  embedded_in :tax_household

  field :e_pdc_id, type: String
  field :benchmark_plan_id, type: BSON::ObjectId

  # Premium tax credit assistance eligibility.
  # Available to household with income between 100% and 400% of the Federal Poverty Level (FPL)
  field :max_aptc, type: Money, default: 0.00

  # Cost-sharing reduction assistance eligibility for co-pays, etc.
  # Available to households with income between 100-250% of FPL and enrolled in Silver plan.
  field :csr_percent_as_integer, type: Integer, default: 0  #values in DC: 0, 73, 87, 94

  field :determined_on, type: DateTime

  validates_presence_of :determined_on, :max_aptc, :csr_percent_as_integer

  include HasFamilyMembers

  def family
    return nil unless tax_household
    tax_household.family
  end

  def benchmark_plan=(benchmark_plan_instance)
    return unless benchmark_plan_instance.is_a? Plan
    self.benchmark_plan_id = benchmark_plan_instance._id
    @benchmark_plan = benchmark_plan_instance
  end

  def benchmark_plan
    return @benchmark_plan if defined? @benchmark_plan
    @benchmark_plan = Plan.find(self.benchmark_plan_id) unless self.benchmark_plan_id.blank?
  end

  def csr_percent=(value)
    value ||= 0 #to handle value = nil
    raise "value out of range" if (value < 0 || value > 1)
    self.csr_percent_as_integer = Rational(value) * Rational(100)
  end

  def csr_percent
    (Rational(csr_percent_as_integer) / Rational(100)).to_f
  end

end
