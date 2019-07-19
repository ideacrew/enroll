module IvlAssistanceWorld
  def update_a_standard_plan_to_be_csr
    Plan.all.each { |plan| plan.update_attributes!(csr_variant_id: "05") }
  end

  def reset_plans_to_be_standard
    Plan.all.each { |plan| plan.update_attributes!(csr_variant_id: "01") }
  end

  def create_tax_household_and_eligibility_determination(family)
    benefit_sponsorship = HbxProfile.current_hbx.benefit_sponsorship
    product = BenefitMarkets::Products::Product.all.where(metal_level_kind: :silver).first
    benefit_sponsorship.benefit_coverage_periods.detect {|bcp| bcp.contains?(TimeKeeper.datetime_of_record)}.update_attributes!(slcsp_id: product.id)
    slcsp_id = HbxProfile.current_hbx.benefit_sponsorship.current_benefit_coverage_period.slcsp_id

    tax_household = family.active_household.tax_households.create(
      effective_starting_on: (TimeKeeper.date_of_record - 30.days),
      is_eligibility_determined: true,
      submitted_at: TimeKeeper.date_of_record
    )

    tax_household.eligibility_determinations.create(
      benchmark_plan_id: slcsp_id,
      max_aptc: 100.00,
      csr_percent_as_integer: 87,
      determined_on: (TimeKeeper.date_of_record - 30.days),
      csr_eligibility_kind: 'csr_87'
    )

    family.active_household.save!
    family.save!
    tax_household
  end

  def create_aptc_only_eligibilty_for_the_family
    family = Family.all.first
    tax_household = create_tax_household_and_eligibility_determination(family)
    tax_household.tax_household_members << TaxHouseholdMember.new(
        applicant_id: family.family_members[0].id,
        is_subscriber: true,
        is_ia_eligible: true,
        is_medicaid_chip_eligible: false
    )
    tax_household.tax_household_members << TaxHouseholdMember.new(
        applicant_id: family.family_members[1].id,
        is_subscriber: false,
        is_ia_eligible: true,
        is_medicaid_chip_eligible: false
    )
    tax_household.save!
    family.active_household.save!
    family.save!
  end

  def create_mixed_eligibilty_for_the_family
    family = Family.all.first
    tax_household = create_tax_household_and_eligibility_determination(family)
    tax_household.tax_household_members << TaxHouseholdMember.new(
        applicant_id: family.family_members[0].id,
        is_subscriber: true,
        is_ia_eligible: true,
        is_medicaid_chip_eligible: false
    )
    tax_household.tax_household_members << TaxHouseholdMember.new(
        applicant_id: family.family_members[1].id,
        is_subscriber: false,
        is_ia_eligible: false,
        is_medicaid_chip_eligible: true
    )
    tax_household.save!
    family.active_household.save!
    family.save!
  end
end

World(IvlAssistanceWorld)
