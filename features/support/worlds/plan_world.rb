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
    HbxEnrollment.order(created_at: :desc).limit(3).each do |newest_enr|
      ids = [newest_enr.product.hios_id]
      id = ids.map { |str| str[0..13] }.first
      qhp = FactoryBot.build(:products_qhp,
                             state_postal_code: EnrollRegistry[:enroll_app].setting(:state_abbreviation).item,
                             active_year: newest_enr.effective_on.year,
                             standard_component_id: id)
      FactoryBot.build(:products_qhp_cost_share_variance, qhp: qhp, hios_plan_and_variant_id: ids.first)
      qhp.save!
    end
  end
end

World(PlanWorld)

Given /a plan year(?:, )?(.*)(?:,) exists/ do |traits|
  plan *traits.sub(/, (and )?/, ',').gsub(' ', '_').split(',').map(&:to_sym), market: 'shop', coverage_kind: 'health', deductible: 4000
end
