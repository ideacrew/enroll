class TaxHouseholdMember
  include Mongoid::Document
  include Mongoid::Timestamps
  include BelongsToFamilyMember
  include ApplicationHelper

  PDC_TYPES = [['Assisted','is_ia_eligible'], ['Medicaid','is_medicaid_chip_eligible'], ['Totally Ineligible','is_totally_ineligible'], ['UQHP','is_uqhp_eligible']].freeze
  CSR_KINDS = ['csr_100', 'csr_94', 'csr_87', 'csr_73', 'csr_0', 'csr_limited'].freeze

  embedded_in :tax_household
  embeds_many :financial_statements

  field :applicant_id, type: BSON::ObjectId
  field :is_ia_eligible, type: Boolean, default: false
  field :is_medicaid_chip_eligible, type: Boolean, default: false
  field :is_totally_ineligible, type: Boolean, default: false
  field :is_uqhp_eligible, type: Boolean, default: false
  field :is_subscriber, type: Boolean, default: false
  field :reason, type: String
  field :is_non_magi_medicaid_eligible, type: Boolean, default: false
  field :magi_as_percentage_of_fpl, type: Float, default: 0.0
  field :magi_medicaid_type, type: String
  field :magi_medicaid_category, type: String
  field :magi_medicaid_monthly_household_income, type: Money, default: 0.00
  field :magi_medicaid_monthly_income_limit, type: Money, default: 0.00
  field :medicaid_household_size, type: Integer
  field :is_without_assistance, type: Boolean, default: false
  field :csr_percent_as_integer, type: Integer, default: 0  #values in DC: 0, 73, 87, 94
  field :csr_eligibility_kind, type: String, default: 'csr_0'

  validate :strictly_boolean

  validates :csr_eligibility_kind,
            allow_blank: false,
            inclusion: { in: CSR_KINDS,
                         message: "%{value} is not a valid cost sharing eligibility kind" }

  alias_method :family_member_id, :applicant_id

  def csr_percent_as_integer=(new_csr_percent)
    super
    self.csr_eligibility_kind = case csr_percent_as_integer
                                when 73
                                  'csr_73'
                                when 87
                                  'csr_87'
                                when 94
                                  'csr_94'
                                when 100
                                  'csr_100'
                                when -1
                                  'csr_limited'
                                else
                                  'csr_0'
                                end
  end

  def eligibility_determinations
    return nil unless tax_household
    tax_household.eligibility_determinations
  end

  def update_eligibility_kinds eligibility_kinds
    return if eligibility_kinds.blank?
    if convert_to_bool(eligibility_kinds['is_ia_eligible']) && convert_to_bool(eligibility_kinds['is_medicaid_chip_eligible'])
      return false
    else
      self.update_attributes eligibility_kinds
      return true
    end
  end

  def family
    return nil unless tax_household
    tax_household.family
  end

  def is_ia_eligible?
    is_ia_eligible && !is_medicaid_chip_eligible && !is_totally_ineligible && !is_uqhp_eligible
  end

  def is_medicaid_chip_eligible?
    !is_ia_eligible && is_medicaid_chip_eligible && !is_totally_ineligible && !is_uqhp_eligible
  end

  def is_subscriber?
    is_subscriber
  end

  def is_primary_applicant?
    family_member.is_primary_applicant
  end

  def strictly_boolean
    unless is_ia_eligible.is_a? Boolean
      self.errors.add(:base, "is_ia_eligible should be a boolean")
    end

    unless is_medicaid_chip_eligible.is_a? Boolean
      self.errors.add(:base, "is_medicaid_chip_eligible should be a boolean")
    end

    unless is_subscriber.is_a? Boolean
      self.errors.add(:base, "is_subscriber should be a boolean")
    end
  end

  def person
    return @person unless @person.blank?
    @person = family_member.person
  end

  def benchmark_product_details_for(effective_date)
    binding.pry
    result = Operations::Products::DetermineSlcspForTaxHouseholdMember.new.call(effective_date: effective_date, tax_household_member: self)
    raise result.failure unless result.success?

    result.success
  end

  def aptc_benchmark_amount(enrollment)
    date = enrollment.effective_on
    slcsp_id = benchmark_product_details_for(date)[:product_id]
    benchmark_product = BenefitMarkets::Products::Product.find(slcsp_id)
    ehb = benchmark_product.ehb
    product = ::BenefitMarkets::Products::ProductFactory.new({product_id: slcsp_id})
    cost = product.cost_for(date, person.age_on(date))
    round_down_float_two_decimals(cost * ehb)
  end

  def age_on_effective_date
    return @age_on_effective_date unless @age_on_effective_date.blank?
    dob = person.dob
    coverage_start_on = TimeKeeper.date_of_record
    return unless coverage_start_on.present?
    age = coverage_start_on.year - dob.year

    # Shave off one year if coverage starts before birthday
    if coverage_start_on.month == dob.month
      age -= 1 if coverage_start_on.day < dob.day
    else
      age -= 1 if coverage_start_on.month < dob.month
    end

    @age_on_effective_date = age
  end
end
