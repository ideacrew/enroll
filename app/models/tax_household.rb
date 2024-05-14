require 'autoinc'

class TaxHousehold
  include Mongoid::Document
  include SetCurrentUser
  include Mongoid::Timestamps
  include HasFamilyMembers
  include Acapi::Notifiers
  include Mongoid::Autoinc
  include FloatHelper

  # A set of applicants, grouped according to IRS and ACA rules, who are considered a single unit
  # when determining eligibility for Insurance Assistance and Medicaid

  embedded_in :household
  embedded_in :tax_household_group

  field :hbx_assigned_id, type: Integer
  increments :hbx_assigned_id, seed: 9999

  field :allocated_aptc, type: Money, default: 0.00
  field :is_eligibility_determined, type: Boolean, default: false

  field :effective_starting_on, type: Date
  field :effective_ending_on, type: Date
  field :submitted_at, type: DateTime

  # New set of fields to support MultiTaxHousehold functionality and new business logic on how to calculate aptc(available)
  field :yearly_expected_contribution, type: Money, default: 0.00
  field :max_aptc, type: Money
  # field :monthly_expected_contribution, type: Money
  field :eligibility_determination_hbx_id, type: BSON::ObjectId
  field :legacy_hbx_assigned_id, type: Integer

  index({ "effective_ending_on" => 1, "effective_starting_on" => 1 })

  embeds_many :tax_household_members, cascade_callbacks: true
  accepts_nested_attributes_for :tax_household_members

  embeds_many :eligibility_determinations, cascade_callbacks: true

  embeds_one :aptc_accumulator
  embeds_one :contribution_accumulator

  scope :tax_household_with_year, ->(year) { where(effective_starting_on: Date.new(year)..Date.new(year).end_of_year) }
  scope :active_tax_household, ->{ where(effective_ending_on: nil) }
  scope :inactive, ->{ where(:effective_ending_on.ne => nil) }
  scope :current_and_prospective_by_year, ->(year) { where(:effective_starting_on.gte => Date.new(year)) }

  validate :validate_dates

  def latest_eligibility_determination
    eligibility_determinations.sort {|a, b| a.determined_at <=> b.determined_at}.last
  end

  def group_by_year
    effective_starting_on.year
  end

  def eligibile_csr_kind(family_member_ids)
    # send shopping family members ids as input
    thh_members = tax_household_members.where(:applicant_id.in => family_member_ids)
    thhm_appid_csr_hash = thh_members.inject({}) do |result, thhm|
      result[thhm.applicant_id] = thhm.csr_eligibility_kind
      result
    end

    if FinancialAssistanceRegistry.feature_enabled?(:native_american_csr)
      thh_members.each do |thh_member|
        family_member = thh_member.family_member
        thhm_appid_csr_hash[family_member.id] = 'csr_limited' if family_member.person.indian_tribe_member && !thh_member.is_ia_eligible
      end
      family_members_with_ai_an = thh_members.map(&:family_member).select { |fm| fm.person.indian_tribe_member }
      thh_members = thh_members.where(:applicant_id.nin => family_members_with_ai_an.map(&:id))
    end
    thh_m_eligibility_kinds = thhm_appid_csr_hash.values.uniq
    (thh_members.pluck(:is_ia_eligible).include?(false) || thh_m_eligibility_kinds.count == 0) ? 'csr_0' : eligibile_csr_kind_for_shopping(thh_m_eligibility_kinds)
  end

  def eligible_csr_percent_as_integer(family_member_ids)
    csr_kind = eligibile_csr_kind(family_member_ids)
    fetch_csr_percent(csr_kind)
  end

  def fetch_csr_percent(csr_kind)
    {
      "csr_0" => 0,
      "csr_limited" => 'limited',
      'csr_100' => 100,
      "csr_94" => 94,
      "csr_87" => 87,
      "csr_73" => 73
    }.stringify_keys[csr_kind] || 0
  end

  def valid_csr_kind(hbx_enrollment)
    eligibile_csr_kind(hbx_enrollment.hbx_enrollment_members.map(&:applicant_id))
  end

  def current_csr_percent
    latest_eligibility_determination.csr_percent
  end

  def current_max_aptc
    eligibility_determination = latest_eligibility_determination
    # TODO: need business rule to decide how to get the max aptc
    # during open enrollment and determined_at
    # Please reference ticket 42408 for more info on the determined on to determined_at migration
    if eligibility_determination.present? #and eligibility_determination.determined_at.year == TimeKeeper.date_of_record.year
      eligibility_determination.max_aptc
    else
      0
    end
  end

  def monthly_expected_contribution
    return 0.0 unless yearly_expected_contribution

    yearly_expected_contribution / 12.0
  end

  def aptc_members
    tax_household_members.find_all(&:is_ia_eligible?)
  end

  def applicant_ids
    tax_household_members.map(&:applicant_id)
  end

  def aptc_ratio_by_member
    # if APTC is $100, we need to apportion it between member
    # For example, given family of 4, with 2 adults & 2 children, all who are eligible
    # Based on SLCSP, we will compute ratio for each member based on premium cost
    # So, if total family premium cost is $1,000, adult premium cost is $350/each and
    # child premium cost is $150/each, APTC ratio will be 35% to each adult and
    # 15% to each child

    # Look up premiums for each aptc_member
    benchmark_member_cost_hash = {}
    aptc_members.each do |member|
      slcsp_id = member.benchmark_product_details_for(effective_starting_on)[:product_id]
      #TODO use which date to calculate premiums by slcp
      product = product_factory.new({product_id: slcsp_id})
      premium = product.cost_for(effective_starting_on, member.age_on_effective_date)
      benchmark_member_cost_hash[member.applicant_id.to_s] = premium
    end

    # Sum premium total for aptc_members
    sum_premium_total = benchmark_member_cost_hash.values.sum.to_f

    # Compute the ratio
    ratio_hash = {}
    benchmark_member_cost_hash.each do |member_id, cost|
      ratio_hash[member_id] = cost/sum_premium_total
    end

    ratio_hash
  rescue => e
    log(e.message, {:severity => 'critical'})
    {}
  end

  def aptc_family_members_by_tax_household
    members = household.hbx_enrollments.enrolled.by_submitted_after_datetime(self.created_at).flat_map(&:hbx_enrollment_members).flat_map(&:family_member).uniq
    members.select{ |family_member| family_member if is_member_aptc_eligible?(family_member)}
  end

  def unwanted_family_members(hbx_enrollment)
    ((family.active_family_members - find_enrolling_fms(hbx_enrollment)) - aptc_family_members_by_tax_household)
  end

  # to get aptc family members from given family members
  def find_aptc_family_members(family_members)
    family_members.inject([]) do |array, family_member|
      array << family_member if tax_household_members.where(applicant_id: family_member.id).and(is_ia_eligible: true).present?
      array.flatten
    end
  end

  # to get non aptc fms from given family members
  def find_non_aptc_fms(family_members)
    family_members.inject([]) do |array, family_member|
      array << family_member if tax_household_members.where(applicant_id: family_member.id).and(is_ia_eligible: false).present?
      array.flatten
    end
  end

  def find_aptc_tax_household_members(family_members)
    tax_household_members.where(:applicant_id.in => family_members.pluck(:id), is_ia_eligible: true)
  end

  # to get family members from given enrollment
  def find_enrolling_fms hbx_enrollment
    hbx_enrollment.hbx_enrollment_members.map(&:family_member)
  end

  # to check if all the enrolling family members are not aptc
  def is_all_non_aptc?(hbx_enrollment)
    enrolling_family_members = find_enrolling_fms(hbx_enrollment)
    find_non_aptc_fms(enrolling_family_members).count == enrolling_family_members.count
  end

  def is_member_aptc_eligible?(family_member)
    aptc_members.map(&:family_member).include?(family_member)
  end

  # Pass hbx_enrollment and get the total amount of APTC available by hbx_enrollment_members
  def total_aptc_available_amount_for_enrollment(hbx_enrollment, effective_on, excluding_enrollment_id = nil)
    return 0 if hbx_enrollment.blank?
    return 0 if is_all_non_aptc?(hbx_enrollment)
    monthly_available_aptc = monthly_max_aptc(hbx_enrollment, effective_on)
    member_aptc_hash = aptc_available_amount_by_member(monthly_available_aptc, excluding_enrollment_id, hbx_enrollment)
    total = family.active_family_members.reduce(0) do |sum, member|
      sum + (member_aptc_hash[member.id.to_s] || 0)
    end
    family_members = unwanted_family_members(hbx_enrollment)
    unchecked_aptc_thhms = find_aptc_tax_household_members(family_members)
    deduction_amount = total_benchmark_amount(unchecked_aptc_thhms, hbx_enrollment) if unchecked_aptc_thhms
    total = total - deduction_amount
    (total < 0.00) ? 0.00 : float_fix(total)
  end

  def monthly_max_aptc(hbx_enrollment, effective_on)
    previous_thh = household.tax_households.tax_household_with_year(self.effective_starting_on.year).where(:created_at.lt => self.created_at).last
    if previous_thh.present?
      prev_thhm_fm_member_ids = previous_thh.tax_household_members.where(is_ia_eligible: true).map(&:applicant_id).sort
      thhm_fm_member_ids = tax_household_members.where(is_ia_eligible: true).map(&:applicant_id).sort
    end

    monthly_max_aggregate = if EnrollRegistry[:calculate_monthly_aggregate].feature.is_enabled && (previous_thh.nil? || (previous_thh.present? && prev_thhm_fm_member_ids == thhm_fm_member_ids))
                              shopping_fm_ids = hbx_enrollment.hbx_enrollment_members.pluck(:applicant_id)
                              input_params = { family: hbx_enrollment.family,
                                               effective_on: effective_on,
                                               shopping_fm_ids: shopping_fm_ids,
                                               subscriber_applicant_id: hbx_enrollment&.subscriber&.applicant_id }
                              monthly_aggregate_amount = EnrollRegistry.lookup(:calculate_monthly_aggregate) {input_params}
                              monthly_aggregate_amount.success? ? monthly_aggregate_amount.value! : 0
                            else
                              current_max_aptc.to_f
                            end
    float_fix(monthly_max_aggregate)
  end

  def total_benchmark_amount(tax_household_members, hbx_enrollment)
    total_sum = 0
    tax_household_members.each do |tax_household_member|
      total_sum += tax_household_member.aptc_benchmark_amount(hbx_enrollment)
    end
    total_sum
  end

  def aptc_available_amount_by_member(monthly_available_aptc, excluding_enrollment_id = nil, hbx_enrollment = nil)
    # Find HbxEnrollments for aptc_members in the current plan year where they have used aptc
    # subtract from available amount
    aptc_available_amount_hash = {}
    aptc_ratio_by_member.each do |member_id, ratio|
      aptc_available_amount_hash[member_id] = monthly_available_aptc.to_f * ratio
    end
    return aptc_available_amount_hash if EnrollRegistry.feature_enabled?(:calculate_monthly_aggregate)

    # FIXME should get hbx_enrollments by effective_starting_on
    enrollments = household.hbx_enrollments_with_aptc_by_year(effective_starting_on.year)
    enrollments = enrollments.where(:id.ne => BSON::ObjectId.from_string(excluding_enrollment_id.to_s)) if excluding_enrollment_id
    enrollments = enrollments.reject{|enr| enr.subscriber.applicant_id == hbx_enrollment.subscriber.applicant_id} if hbx_enrollment #Since when subscribers are same, existing enrollment for the month will get canceled/termed
    enrollments.map(&:hbx_enrollment_members).flatten.each do |enrollment_member|
      applicant_id = enrollment_member.applicant_id.to_s
      if aptc_available_amount_hash.has_key?(applicant_id)
        aptc_available_amount_hash[applicant_id] -= (enrollment_member.applied_aptc_amount || 0).try(:to_f)
      end
    end
    aptc_available_amount_hash
  end

  def total_aptc_available_amount
    aptc_available_amount_by_member.present? ? aptc_available_amount_by_member.values.sum : 0
  end

  # Pass a list of tax_household_members and get amount of APTC available
  def aptc_available_amount_for_enrollment(hbx_enrollment, plan, elected_aptc)
    # APTC may be used only for Health, return 0 if plan.coverage_kind == "dental"
    aptc_available_amount_hash_for_enrollment = {}

    total_aptc_available_amount = total_aptc_available_amount_for_enrollment(hbx_enrollment)
    elected_pct = total_aptc_available_amount > 0 ? (elected_aptc / total_aptc_available_amount.to_f) : 0
    decorated_plan = UnassistedPlanCostDecorator.new(plan, hbx_enrollment)
    hbx_enrollment.hbx_enrollment_members.each do |enrollment_member|
      given_aptc = (aptc_available_amount_by_member[enrollment_member.applicant_id.to_s] || 0) * elected_pct
      ehb_premium = decorated_plan.premium_for(enrollment_member) * plan.ehb
      aptc_available_amount_hash_for_enrollment[enrollment_member.applicant_id.to_s] = if plan.kind == 'dental'
                                                                                         0
                                                                                       else
                                                                                         [given_aptc, ehb_premium].min
                                                                                       end
    end
    aptc_available_amount_hash_for_enrollment

    # premium_total = as_dollars(policy.pre_amt_tot)
    # given_aptc = as_dollars(policy.applied_aptc)
    # max_aptc = as_dollars(premium_total * plan.ehb)
    # correct_aptc = (given_aptc > max_aptc) ? max_aptc : given_aptc
    # policy.applied_aptc = correct_aptc
    # $70
  end

  # Income sum of all tax filers in this Household for specified year
  def total_incomes_by_year
    applicant_links.inject({}) do |acc, per|
      p_incomes = per.financial_statements.inject({}) do |acc, ae|
        acc.merge(ae.total_incomes_by_year) { |k, ov, nv| ov + nv }
      end
      acc.merge(p_incomes) { |k, ov, nv| ov + nv }
    end
  end

  #TODO: return count for adults (21-64), children (<21) and total
  def size
    members.size
  end

  def family
    if household
      household.family
    elsif tax_household_group
      tax_household_group.family
    end
  end

  #usage: filtering through group_by criteria
  def group_by_year
    effective_starting_on.year
  end

  def is_eligibility_determined?
    if self.elegibility_determinizations.size > 0
      true
    else
      false
    end
  end

  #primary applicant is the tax household member who is the subscriber
  def primary_applicant
    tax_household_members.detect do |tax_household_member|
      tax_household_member.is_subscriber == true
    end
  end

  # TODO: Refactor this to return Applicants vs TaxHouseholdMembers after FAA merge.
  def tax_members
    tax_household_members
  end

  def thhm_by(family_member)
    return nil unless family_member.is_a?(FamilyMember)

    tax_household_members.where(applicant_id: family_member.id).first
  end

  private

  def validate_dates
    if effective_ending_on.present? && effective_starting_on > effective_ending_on
      errors.add(:effective_ending_on, "can't occur before start date")
    end
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  def eligibile_csr_kind_for_shopping(csr_kind_list)
    return 'csr_0' if csr_kind_list.include?('csr_0') || (csr_kind_list.include?('csr_limited') && (csr_kind_list.include?('csr_73') || csr_kind_list.include?('csr_87') || csr_kind_list.include?('csr_94')))
    return 'csr_limited' if csr_kind_list.include?('csr_limited')
    return 'csr_73' if csr_kind_list.include?('csr_73')
    return 'csr_87' if csr_kind_list.include?('csr_87')
    return 'csr_94' if csr_kind_list.include?('csr_94')
    return 'csr_100' if csr_kind_list.include?('csr_100')
    'csr_0'
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  def product_factory
    ::BenefitMarkets::Products::ProductFactory
  end
end
