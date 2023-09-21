# frozen_string_literal: true

class Enrollments::IndividualMarket::FamilyEnrollmentRenewal
  include FloatHelper
  include Config::AcaHelper
  attr_accessor :enrollment, :renewal_coverage_start, :assisted, :aptc_values

  CAT_AGE_OFF_HIOS_IDS = ["94506DC0390008", "86052DC0400004"]

  def initialize
    @logger = Logger.new("#{Rails.root}/log/family_enrollment_renewal_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
  end

  def renew
    set_csr_value if enrollment.is_health_enrollment?
    renewal_enrollment = clone_enrollment
    populate_aptc_hash(renewal_enrollment) if renewal_enrollment.is_health_enrollment?

    can_renew = ::Operations::Products::ProductOfferedInServiceArea.new.call({enrollment: renewal_enrollment})

    raise "Cannot renew enrollment #{enrollment.hbx_id}. Error: #{can_renew.failure}" unless can_renew.success?

    save_renewal_enrollment(renewal_enrollment)

    # elected aptc should be the minimun between applied_aptc and EHB premium.
    renewal_enrollment = assisted_enrollment(renewal_enrollment) if @assisted.present? && renewal_enrollment.is_health_enrollment?
    renewal_enrollment.renew_enrollment
    verify_and_set_osse_minimum_aptc(renewal_enrollment) if @assisted
    renewal_enrollment.update_osse_childcare_subsidy
    save_renewal_enrollment(renewal_enrollment)
  rescue StandardError => e
    @logger.info "Enrollment renewal failed for #{enrollment.hbx_id} with error message: #{e} backtrace: #{e.backtrace.join('\n')}"
  end

  def clone_enrollment
    renewal_enrollment = HbxEnrollment.new
    renewal_enrollment.family_id = @enrollment.family_id
    renewal_enrollment.household_id = @enrollment.household_id
    renewal_enrollment.consumer_role_id = @enrollment.consumer_role_id
    renewal_enrollment.resident_role_id = @enrollment.resident_role_id
    renewal_enrollment.effective_on = renewal_coverage_start
    renewal_enrollment.rating_area_id = ::BenefitMarkets::Locations::RatingArea.rating_area_for((@enrollment.consumer_role || @enrollment.resident_role).rating_address, during: renewal_coverage_start)&.id
    renewal_enrollment.coverage_kind = @enrollment.coverage_kind
    renewal_enrollment.enrollment_kind = "open_enrollment"
    renewal_enrollment.kind = @enrollment.kind
    renewal_enrollment.external_id = @enrollment.external_id
    renewal_enrollment.hbx_enrollment_members = clone_enrollment_members
    renewal_enrollment.product_id = fetch_product_id(renewal_enrollment)
    renewal_enrollment.is_any_enrollment_member_outstanding = @enrollment.is_any_enrollment_member_outstanding

    renewal_enrollment
  end

  def fetch_product_id(renewal_enrollment)
    # TODO: Fetch proper csr product as the family might be eligible for a
    # different csr value than that of given externally.
    return renewal_product if has_catastrophic_product?

    if can_renew_assisted_product?(renewal_enrollment)
      assisted_renewal_product
    else
      renewal_product
    end
  end

  def set_csr_value
    return unless EnrollRegistry.feature_enabled?(:temporary_configuration_enable_multi_tax_household_feature)

    csr_op = ::Operations::PremiumCredits::FindCsrValue.new.call({
                                                                   family: enrollment.family,
                                                                   year: renewal_coverage_start.year,
                                                                   family_member_ids: enrolled_family_member_ids
                                                                 })
    return unless csr_op.success?

    @aptc_values[:csr_amt] = fetch_csr_percent(csr_op.value!)
  end

  def populate_aptc_hash(renewal_enrollment)
    return unless EnrollRegistry.feature_enabled?(:temporary_configuration_enable_multi_tax_household_feature)

    aptc_op = ::Operations::PremiumCredits::FindAptc.new.call({
                                                                hbx_enrollment: renewal_enrollment,
                                                                effective_on: renewal_enrollment.effective_on
                                                              })
    return unless aptc_op.success?

    max_aptc = aptc_op.value!
    default_percentage = EnrollRegistry[:aca_individual_assistance_benefits].setting(:default_applied_aptc_percentage).item
    applied_percentage = enrollment.elected_aptc_pct > 0 ? enrollment.elected_aptc_pct : default_percentage
    ehb_premium = renewal_enrollment.total_ehb_premium
    applied_aptc = float_fix([(max_aptc * applied_percentage), ehb_premium].min)
    @assisted = true if max_aptc > 0.0

    @aptc_values.merge!({
                          applied_percentage: applied_percentage,
                          applied_aptc: applied_aptc,
                          max_aptc: max_aptc,
                          ehb_premium: ehb_premium
                        })
  end

  def verify_and_set_osse_minimum_aptc(renewal_enrollment)
    applied_aptc_pct = applied_aptc_pct_for(renewal_enrollment)
    return if applied_aptc_pct == renewal_enrollment.elected_aptc_pct

    calculated_aptc_pct = renewal_enrollment.applied_aptc_amount.to_f / aptc_values[:max_aptc]
    if calculated_aptc_pct == renewal_enrollment.elected_aptc_pct
      applied_aptc = @aptc_values[:max_aptc] * applied_aptc_pct
    else
      ehb_premium = renewal_enrollment.total_ehb_premium
      applied_aptc = [(@aptc_values[:max_aptc] * applied_aptc_pct), ehb_premium].min
    end

    renewal_enrollment.update(
      applied_aptc_amount: float_fix(applied_aptc),
      elected_aptc_pct: applied_aptc_pct
    )
  end

  def applied_aptc_pct_for(renewal_enrollment)
    if renewal_enrollment.ivl_osse_eligible? && osse_aptc_minimum_enabled?
      return renewal_enrollment.elected_aptc_pct if renewal_enrollment.elected_aptc_pct >= minimum_applied_aptc_pct_for_osse.to_f
      minimum_applied_aptc_pct_for_osse
    else
      renewal_enrollment.elected_aptc_pct > 0 ? renewal_enrollment.elected_aptc_pct : default_applied_aptc_pct
    end
  end

  def can_renew_assisted_product?(renewal_enrollment)
    return false unless renewal_enrollment.is_health_enrollment?
    return true if EnrollRegistry.feature_enabled?(:temporary_configuration_enable_multi_tax_household_feature) && @aptc_values[:csr_amt].present?
    return false unless @assisted

    tax_household = enrollment.family.active_household.latest_active_thh_with_year(renewal_coverage_start.year)
    members = tax_household.tax_household_members
    enrollment_members_in_thh = members.where(:applicant_id.in => renewal_enrollment.hbx_enrollment_members.map(&:applicant_id))
    enrollment_members_in_thh.all? {|m| m.is_ia_eligible == true}
  end

  def enrolled_family_member_ids
    enrollment.hbx_enrollment_members.map(&:applicant_id)
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

  def assisted_enrollment(renewal_enrollment)
    renewal_service = Services::IvlEnrollmentRenewalService.new(renewal_enrollment)
    renewal_service.assign(@aptc_values)
  end

  # Assisted
  # Tax household > eligibility determinations
  #  - latest eligibility determation
  #  - current CSR elgibility kind
  #  - max APTC
  def renewal_eligiblity_determination; end

  # Cat product ageoff
  # Eligibility determination CSR change
  def renewal_product
    if @enrollment.coverage_kind == 'dental'
      renewal_product = @enrollment.product.renewal_product_id
    elsif has_catastrophic_product? && is_cat_product_ineligible?
      renewal_product = fetch_cat_age_off_product(@enrollment.product)
      raise "#{renewal_coverage_start.year} Catastrophic age off product missing on HIOS id #{@enrollment.product.hios_id}" if renewal_product.blank?
    else
      renewal_product = if @enrollment.product.csr_variant_id == '01' || has_catastrophic_product?
                          @enrollment.product.renewal_product_id
                        else
                          ::BenefitMarkets::Products::HealthProducts::HealthProduct.by_year(renewal_coverage_start.year).where(
                            {:hios_id => "#{@enrollment.product.renewal_product.hios_base_id}-01"}
                          ).first.id
                        end
    end

    raise "#{renewal_coverage_start.year} renewal product missing on HIOS id #{@enrollment.product.hios_id}" if renewal_product.blank?

    renewal_product
  end

  def fetch_csr_variant
    @aptc_values[:csr_amt] == '0' ? '01' : EligibilityDetermination::CSR_KIND_TO_PLAN_VARIANT_MAP["csr_#{@aptc_values[:csr_amt]}"]
  end

  def fetch_cat_age_off_product(product)
    # As per ticket: 61716
    # FIXME: DON'T EVER DO THIS!
    # We are incrementing the year to do for all future years too,
    # which won't work because the HIOS IDs won't be the same
    if renewal_coverage_start.year.to_i >= 2020 && CAT_AGE_OFF_HIOS_IDS.include?(product.hios_base_id)
      base_id = if product.hios_base_id == "94506DC0390008"
                  "94506DC0390010"
                elsif product.hios_base_id == "86052DC0400004"
                  "86052DC0400010"
                end
      ::BenefitMarkets::Products::HealthProducts::HealthProduct.by_year(renewal_coverage_start.year).where(
        {:hios_id => "#{base_id}-01"}
      ).first.id
    else
      product.catastrophic_age_off_product_id
    end
  end

  def assisted_renewal_product
    # TODO: Make sure tax households create script treats 0 as 100
    if @aptc_values[:csr_amt].present?
      eligible_csr_variant = EligibilityDetermination::CSR_KIND_TO_PLAN_VARIANT_MAP["csr_#{@aptc_values[:csr_amt]}"]
      if @enrollment.product.metal_level == "silver" || ['02', '03'].include?(eligible_csr_variant)
        csr_variant = fetch_csr_variant
        product = fetch_product(csr_variant)
        return product.id if product

        fetch_product("01").id
      elsif eligible_csr_variant == '01'
        fetch_product("01")&.id || @enrollment.product.renewal_product_id
      else
        product = fetch_product(eligible_csr_variant) || fetch_product('01')
        return product.id if product
        @enrollment.product.renewal_product_id
      end
    else
      @enrollment.product.renewal_product_id
    end
  end

  def fetch_product(csr_variant)
    ::BenefitMarkets::Products::HealthProducts::HealthProduct.by_year(renewal_coverage_start.year).where(
      {:hios_id => "#{@enrollment.product.renewal_product.hios_base_id}-#{csr_variant}"}
    ).first
  end

  def has_catastrophic_product?
    @enrollment.product.metal_level_kind == :catastrophic
  end

  def is_cat_product_ineligible?
    @enrollment.hbx_enrollment_members.any? do |member|
      member.person.age_on(renewal_coverage_start) > 29
    end
  end

  def slcsp_feature_enabled?(renewal_year)
    EnrollRegistry.feature_enabled?(:atleast_one_silver_plan_donot_cover_pediatric_dental_cost) &&
      EnrollRegistry[:atleast_one_silver_plan_donot_cover_pediatric_dental_cost]&.settings(renewal_year.to_s.to_sym)&.item
  end

  # Check if member turned 19 during renewal and has pediatric only Qualified Dental Plan
  def turned_19_during_renewal_with_pediatric_only_qdp?(member)
    return false unless slcsp_feature_enabled?(renewal_coverage_start.year)
    return false if enrollment.is_health_enrollment?
    return false unless dental_renewal_product.allows_child_only_offering?

    member.person.age_on(renewal_coverage_start) >= 19
  end

  # Find the dental product using renewal_product_id
  def dental_renewal_product
    @dental_renewal_product ||= ::BenefitMarkets::Products::DentalProducts::DentalProduct.find(renewal_product)
  end

  # rubocop:disable Style/RedundantReturn
  def eligible_to_get_covered?(member)
    child_relations = %w[child ward foster_child adopted_child]
    return true unless child_relations.include?(member.family_member.relationship)

    return false if turned_19_during_renewal_with_pediatric_only_qdp?(member)

    return true if member.family_member.age_off_excluded

    if EnrollRegistry.feature_enabled?(:age_off_relaxed_eligibility)
      dependent_coverage_eligible = ::EnrollRegistry[:age_off_relaxed_eligibility] do
        {
          effective_on: renewal_coverage_start,
          family_member: member&.family_member,
          market_key: :aca_individual_dependent_age_off,
          relationship_kind: member.family_member.relationship
        }
      end
      return true if dependent_coverage_eligible.success?
    elsif child_relations.include?(member.family_member.relationship)
      return true if member.person.age_on(renewal_coverage_start.prev_day) < 26
    end

    return false
  end
  # rubocop:enable Style/RedundantReturn

  def eligible_enrollment_members
    @enrollment.hbx_enrollment_members.select do |member|
      if member.person.is_consumer_role_active?
        consumer_role = member.person.consumer_role

        eligible_to_get_covered?(member) &&
          residency_status_satisfied?(member, consumer_role) &&
          citizenship_status_satisfied?(consumer_role) &&
          !member.person.is_disabled &&
          !member.person.is_incarcerated &&
          member.person.is_applying_coverage
      elsif member.person.is_resident_role_active?
        eligible_to_get_covered?(member) && !member.person.is_disabled && !member.person.is_incarcerated
      else
        false
      end
    end
  end

  # TODO: IndividualMarket
  #   1. Research on the differences b/w the eligibility checks in the enrollment renewal code and InsuredEligibleForBenefitRule
  #   2. Point to InsuredEligibleForBenefitRule for all member eligibility checks in the enrollment renewal context
  # Start: Residency Status & Citizenship Member Eligibility Checks
  def citizenship_status_satisfied?(role)
    return true if role.is_a?(ResidentRole)
    return false if role.citizen_status.blank?

    ConsumerRole::INELIGIBLE_CITIZEN_VERIFICATION.exclude?(role.citizen_status)
  end

  def residency_status_satisfied?(member, role)
    return false if ivl_benefit.blank?
    return true if ivl_benefit.residency_status.include?('any')
    return false unless ivl_benefit.residency_status.include?('state_resident') && role.present?
    return true if role.person.is_dc_resident?

    member.hbx_enrollment.family.active_family_members.any? do |family_member|
      family_member.age_on(renewal_coverage_start) >= 19 && family_member.is_dc_resident?
    end
  end

  def ivl_benefit
    return @ivl_benefit if defined?(@ivl_benefit)
    benefit_cp = HbxProfile.current_hbx.benefit_sponsorship.benefit_coverage_periods.detect do |bcp|
      bcp.contains?(renewal_coverage_start)
    end
    return nil unless benefit_cp

    @ivl_benefit = benefit_cp.benefit_packages.detect do |bp|
      bp.effective_year == renewal_coverage_start.year && bp.benefit_categories.include?(@enrollment.coverage_kind)
    end
  end
  # End: Residency Status & Citizenship Member Eligibility Checks

  def clone_enrollment_members
    old_enrollment_members = eligible_enrollment_members
    raise "unable to generate enrollment with hbx_id #{@enrollment.hbx_id} due to no enrollment members not present" if old_enrollment_members.blank?

    latest_enrollment = @enrollment.family.active_household.hbx_enrollments.where(:aasm_state.nin => ['shopping']).order_by(:created_at.desc).first
    old_enrollment_members.inject([]) do |members, hbx_enrollment_member|
      member = latest_enrollment.hbx_enrollment_members.where(applicant_id: hbx_enrollment_member.applicant_id).first
      tobacco_use = member&.tobacco_use || 'N'
      members << HbxEnrollmentMember.new({ applicant_id: hbx_enrollment_member.applicant_id,
                                           eligibility_date: renewal_coverage_start,
                                           coverage_start_on: renewal_coverage_start,
                                           is_subscriber: hbx_enrollment_member.is_subscriber,
                                           carrier_member_id: hbx_enrollment_member.carrier_member_id,
                                           external_id: hbx_enrollment_member.external_id,
                                           tobacco_use: tobacco_use})
    end
  end

  def save_renewal_enrollment(renewal_enrollment)
    if renewal_enrollment.save
      renewal_enrollment
    else
      message = "Enrollment: #{@enrollment.hbx_id}, \n" \
      "Error(s): \n #{renewal_enrollment.errors.map{|k,v| "#{k} = #{v}"}.join(" & \n")} \n"
      @logger.info message
    end
  end
end
