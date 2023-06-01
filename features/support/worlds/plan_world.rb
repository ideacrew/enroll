module PlanWorld
  def plan(*traits)
    attributes = traits.extract_options!
    @plan ||= FactoryBot.create :plan, *traits, attributes
  end

  def create_cat_product
    issuer_profile = FactoryBot.create(:benefit_sponsors_organizations_issuer_profile)
    FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: 'aca_individual', issuer_profile: issuer_profile, metal_level_kind: :catastrophic)
  end

  def create_kaiser_product
    issuer_profile = FactoryBot.create(:benefit_sponsors_organizations_issuer_profile, :kaiser_profile)
    FactoryBot.create(
      :benefit_markets_products_health_products_health_product,
      benefit_market_kind: 'aca_individual',
      issuer_profile: issuer_profile,
      metal_level_kind: :catastrophic
    )
  end

  def create_anthm_product
    issuer_profile = FactoryBot.create(:benefit_sponsors_organizations_issuer_profile, :anthm_profile)
    FactoryBot.create(
      :benefit_markets_products_health_products_health_product,
      benefit_market_kind: 'aca_individual',
      issuer_profile: issuer_profile,
      metal_level_kind: :catastrophic
    )
  end

  def create_qhp
    newest_enr = HbxEnrollment.order(created_at: :desc).first
    ids = [newest_enr.product.hios_id]
    id = ids.map { |str| str[0..13] }.first
    qhp = FactoryBot.build(:products_qhp,
                           state_postal_code: EnrollRegistry[:enroll_app].setting(:state_abbreviation).item,
                           active_year: newest_enr.effective_on.year,
                           standard_component_id: id)
    FactoryBot.build(:products_qhp_cost_share_variance, qhp: qhp, hios_plan_and_variant_id: ids.first)
    qhp.save!
  end

  def create_csr_73_bp_without_silver_plans
    bcps = HbxProfile.current_hbx.benefit_sponsorship.benefit_coverage_periods
    bcps.each do |bcp|
      bp = FactoryBot.build(:benefit_package, :with_csr_73_benefit_eligibility_element_group, benefit_coverage_period: bcp)
      bp.save!
    end
  end

  def create_csr_0_bp_with_silver_plans
    bcps = HbxProfile.current_hbx.benefit_sponsorship.benefit_coverage_periods
    bcps.each do |bcp|
      FactoryBot.create(:benefit_package, :with_csr_0_benefit_eligibility_element_group, benefit_coverage_period: bcp, coverage_year: bcp.start_on.year)
    end
    bcps.flat_map(&:benefit_packages).each do |bp|
      BenefitMarkets::Products::HealthProducts::HealthProduct.where(:id.in => bp.benefit_ids).each do |health_pro|
        health_pro.update_attributes!(csr_variant_id: '01', hios_id: "#{health_pro.hios_base_id}-01", metal_level_kind: :silver)
      end
    end
  end
end

World(PlanWorld)

Given /a plan year(?:, )?(.*)(?:,) exists/ do |traits|
  plan *traits.sub(/, (and )?/, ',').gsub(' ', '_').split(',').map(&:to_sym), market: 'shop', coverage_kind: 'health', deductible: 4000
end
