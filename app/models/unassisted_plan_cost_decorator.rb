# frozen_string_literal: true

class UnassistedPlanCostDecorator < SimpleDelegator
  include FloatHelper

  attr_reader :hbx_enrollment, :elected_aptc, :child_age_limit

  DISCOUNT_EXEMPT_RELATIONSHIPS = [
    "spouse",
    "domestic_partner",
    "life_partner"
  ].freeze

  def initialize(plan, hbx_enrollment, elected_aptc = 0, _tax_household = nil)
    super(plan)
    @hbx_enrollment = hbx_enrollment
    @elected_aptc = elected_aptc.to_f
    @child_age_limit = EnrollRegistry[:enroll_app].setting(:child_age_limit).item
    @can_round_cents = can_round_cents?
  end

  def members
    hbx_enrollment.hbx_enrollment_members
  end

  def schedule_date
    @hbx_enrollment.effective_on
  end

  def age_of(member)
    member.age_on_effective_date
  end

  def ordered_children
    @ordered_children ||= begin
      non_spouse_or_child_subscribers = members.reject do |m|
        (m.is_subscriber? && m.primary_relationship != 'child') || DISCOUNT_EXEMPT_RELATIONSHIPS.include?(m.primary_relationship)
      end
      not_too_old = non_spouse_or_child_subscribers.select do |mem|
        age_of(mem) <= child_age_limit
      end
      not_too_old.sort_by { |m| age_of(m) }.reverse
    end
  end

  def child_index(member)
    @children ||= ordered_children
    @children.index(member)
  end

  def large_family_factor(member)
    zero_permium_policy_disabled = EnrollRegistry[:zero_permium_policy].disabled?

    if (age_of(member) > child_age_limit) || (kind == :dental && zero_permium_policy_disabled)
      1.00
    elsif child_index(member).present? && child_index(member) > 2
      0.00
    else
      1.00
    end
  end

  def rating_area
    geographic_rating_area_model = EnrollRegistry[:enroll_app].setting(:geographic_rating_area_model).item
    if geographic_rating_area_model == 'single'
      __getobj__.premium_tables.first.rating_area.exchange_provided_code
    else
      hbx_enrollment.rating_area.exchange_provided_code
    end
  end

  #TODO: FIX me to refactor hard coded rating area
  def premium_for(member)
    (::BenefitMarkets::Products::ProductRateCache.lookup_rate(__getobj__, schedule_date, age_of(member), rating_area, tobacco_use_for(member)) * large_family_factor(member)).round(2)
  rescue StandardError => e
    warn e.inspect unless Rails.env.test?
    warn e.backtrace unless Rails.env.test?
    0
  end

  def premium_for_non_tobacco_use(member)
    (::BenefitMarkets::Products::ProductRateCache.lookup_rate(__getobj__, schedule_date, age_of(member), rating_area) * large_family_factor(member)).round(2)
  rescue StandardError => e
    warn e.inspect unless Rails.env.test?
    warn e.backtrace unless Rails.env.test?
    0
  end

  def employer_contribution_for(_member)
    0.00
  end

  def tobacco_use_for(member)
    member.tobacco_use || 'NA'
  end

  def all_members_aptc_for_saved_enrs
    serv_obj = ::Services::ApplicableAptcService.new(@hbx_enrollment.id, @hbx_enrollment.effective_on, @elected_aptc, [__getobj__.id.to_s])
    serv_obj.aptc_per_member[__getobj__.id.to_s]
  end

  def all_members_aptc_for_unsaved_enrs
    fac_obj = ::Factories::IvlPlanShoppingEligibilityFactory.new(@hbx_enrollment, @hbx_enrollment.effective_on, @elected_aptc, [__getobj__.id.to_s])
    fac_obj.fetch_aptc_per_member[__getobj__.id.to_s]
  end

  def all_members_aptc
    @all_members_aptc ||= @hbx_enrollment.persisted? ? all_members_aptc_for_saved_enrs : all_members_aptc_for_unsaved_enrs
  end

  def aptc_amount(member)
    return 0.00 if @elected_aptc <= 0

    member_premium = premium_for(member)
    member_premium = (member_premium * __getobj__.ehb)
    aptc_amount = all_members_aptc[member.applicant_id.to_s] if member_premium == 0 #TODO: revisit since we always want a aptc amount for member
    aptc_amount ||= [all_members_aptc[member.applicant_id.to_s], member_premium].min

    return aptc_amount unless @member_bool_hash[member.id.to_s]
    round_down_float_two_decimals(aptc_amount)
  end

  def employee_cost_for(member)
    cost = (premium_for(member) - aptc_amount(member)).round(2)
    return cost if large_family_factor(member) == 0 && cost <= 0

    cost = 0.00 if cost < 0
    (cost * large_family_factor(member)).round(2)
  end

  def total_premium
    return family_tier_total_premium if family_tier_eligible?
    members.reduce(0.00) do |sum, member|
      (sum + premium_for(member)).round(2)
    end
  end

  def family_tier_total_premium
    qhp = ::Products::Qhp.where(standard_component_id: __getobj__.hios_base_id, active_year: __getobj__.active_year).first
    qpt = qhp.qhp_premium_tables.where(rate_area_id: hbx_enrollment.rating_area.exchange_provided_code).first
    qpt&.send(@hbx_enrollment.family_tier_value)
  end

  def total_employer_contribution
    0.00
  end

  def total_aptc_amount
    return [@elected_aptc, total_ehb_premium].min if EnrollRegistry.feature_enabled?(:temporary_configuration_enable_multi_tax_household_feature)
    return @elected_aptc if family_tier_eligible?

    result = members.reduce(0.00) do |sum, member|
      (sum + aptc_amount(member))
    end

    return result unless @can_round_cents

    round_down_float_two_decimals(result)
  end

  def total_employee_cost
    return (total_premium - total_aptc_amount - total_childcare_subsidy_amount) if EnrollRegistry.feature_enabled?(:temporary_configuration_enable_multi_tax_household_feature)

    if family_tier_eligible?
      cost = (family_tier_total_premium - total_aptc_amount - total_childcare_subsidy_amount).round(2)
      cost = 0.00 if cost < 0
      return cost
    end

    members.reduce(0.00) do |sum, member|
      (sum + employee_cost_for(member)).round(2)
    end.round(2)
  end

  def aptc_eligible_member_ids
    result = ::Operations::PremiumCredits::FindAll.new.call({ family: hbx_enrollment.family, year: hbx_enrollment.effective_on.year, kind: 'AdvancePremiumAdjustmentGrant' })
    return [] if result.failure?

    grants = result.value!
    return [] if grants.blank?

    grants.map(&:member_ids).flatten
  end

  def total_ehb_premium
    ehb_members = if EnrollRegistry.feature_enabled?(:temporary_configuration_enable_multi_tax_household_feature)
                    return hbx_enrollment.ehb_premium.to_f if !hbx_enrollment.shopping? && hbx_enrollment.ehb_premium.to_f > 0

                    # total_ehb_premium is to cap group's applied aptc value. We should be only considering aptc eligible members.
                    eligible_member_ids = aptc_eligible_member_ids
                    eligible_members = members.select {|member| eligible_member_ids.include?(member.applicant_id.to_s) }

                    eligible_members.present? ? eligible_members : members
                  else
                    members
                  end

    ehb_members.reduce(0.00) do |sum, member|
      (sum + round_down_float_two_decimals(member_ehb_premium(member)))
    end
  end

  def member_ehb_premium(member)
    mem_premium = premium_for(member)
    return mem_premium if mem_premium.to_d == 0.00.to_d

    result = mem_premium * __getobj__.ehb
    return result unless EnrollRegistry.feature_enabled?(:total_minimum_responsibility)
    (mem_premium - result >= 1) ? result : (mem_premium - 1)
  end

  def total_childcare_subsidy_amount
    return 0.00 unless ivl_osse_eligible?
    total_premium - total_aptc_amount
  end

  def ivl_osse_eligible?
    hbx_enrollment.ivl_osse_eligible?
  end

  private

  def can_round_cents?
    return false if elected_aptc <= 0
    return false if family_based_rating?

    if @hbx_enrollment.persisted?
      serv_obj = ::Services::ApplicableAptcService.new(hbx_enrollment.id, hbx_enrollment.effective_on, elected_aptc, [__getobj__.id.to_s])
      member_hash = serv_obj.elected_aptc_per_member
    else
      fac_obj = ::Factories::IvlPlanShoppingEligibilityFactory.new(@hbx_enrollment, @hbx_enrollment.effective_on, elected_aptc, [__getobj__.id.to_s])
      member_hash = fac_obj.fetch_elected_aptc_per_member
    end

    @member_bool_hash = members.inject({}) do |result, member|
      member_premium = premium_for(member)
      result[member.id.to_s] = member_hash[member.id.to_s] > (member_premium * __getobj__.ehb)
      result
    end
    @member_bool_hash.values.all?
  end

  def family_tier_eligible?
    @family_tier_eligible ||= family_based_rating? && is_ivl_product?
  end

  def family_based_rating?
    @family_based_rating ||= __getobj__.family_based_rating?
  end

  def is_ivl_product?
    @is_ivl_product ||= __getobj__.benefit_market_kind == :aca_individual
  end
end
