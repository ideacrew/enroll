# frozen_string_literal: true

module IvlAssistanceWorld
  def update_a_standard_plan_to_be_csr
    products = ::BenefitMarkets::Products::Product.health_products.where(metal_level_kind: :silver)
    products.each do |product|
      product.update_attributes!(csr_variant_id: '02', is_standard_plan: false)
    end
  end

  def reset_plans_to_be_standard
    products = ::BenefitMarkets::Products::Product.health_products.where(metal_level_kind: :silver)
    products.each do |product|
      product.update_attributes!(csr_variant_id: '01', is_standard_plan: true)
    end
  end

  def create_tax_household_and_eligibility_determination(family)
    tax_household = TaxHousehold.new(
      effective_starting_on: TimeKeeper.date_of_record,
      is_eligibility_determined: true,
      submitted_at: TimeKeeper.date_of_record
      )
    family.active_household.tax_households.destroy_all
    family.active_household.tax_households << tax_household
    family.active_household.save!
    tax_household.eligibility_determinations << EligibilityDetermination.new(
      source: 'Admin',
      max_aptc: 100.00,
      csr_percent_as_integer: 100,
      determined_at: TimeKeeper.date_of_record
      )
    tax_household.eligibility_determinations.each { |ed| ed.save!}
    tax_household.save!
    family.save!
    tax_household
  end

  def create_aptc_only_eligibilty_for_the_family
    create_slcsp_product
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

  def create_slcsp_product
    date = TimeKeeper.date_of_record
    benefit_sponsorship = HbxProfile.current_hbx.benefit_sponsorship
    current_benefit_coverage_period = benefit_sponsorship.benefit_coverage_periods.detect {|bcp| bcp.contains?(date)}
    future_benefit_coverage_period = benefit_sponsorship.benefit_coverage_periods.detect {|bcp| bcp.contains?(date + 1.year)}
    current_silver_product = BenefitMarkets::Products::Product.all.aca_individual_market.by_year(date.year).by_metal_level_kind('silver').first
    future_silver_product =  BenefitMarkets::Products::Product.all.aca_individual_market.by_year((date + 1.year).year).by_metal_level_kind('silver').first
    current_benefit_coverage_period.update_attributes(slcsp_id: current_silver_product.id)
    future_benefit_coverage_period.update_attributes(slcsp_id: future_silver_product.id)
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

  def create_enrollment_for_family(family)
    enrollment = FactoryBot.create(:hbx_enrollment, :with_enrollment_members,
                                   :family => family,
                                   :household => family.active_household,
                                   :aasm_state => 'coverage_selected',
                                   :is_any_enrollment_member_outstanding => true,
                                   :kind => 'individual',
                                   :product => create_cat_product,
                                   :effective_on => TimeKeeper.date_of_record.beginning_of_year)
    family.family_members.each do |fm|
      FactoryBot.create(:hbx_enrollment_member, applicant_id: fm.id, eligibility_date: (TimeKeeper.date_of_record - 2.months), hbx_enrollment: enrollment)
    end
    enrollment.save!
    enrollment
  end

  def create_thh_for_family
    person = FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role)
    family = FactoryBot.create(:family, :with_primary_family_member, person: person)
    create_tax_household_and_eligibility_determination(family)
    @enrollment = create_enrollment_for_family(family)
  end

  def create_multiple_member_enrollment_for_family_with_one_minor
    person = FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role)
    family = FactoryBot.create(:family, :with_nuclear_family, person: person)
    family.family_members.last.person.update_attributes!(dob: TimeKeeper.date_of_record - 10.years)
    @enrollment = create_enrollment_for_family(family)
    @enrollment.update_attributes!(consumer_role_id: person.consumer_role.id)
  end

  def enable_change_tax_credit_button
    current_year = TimeKeeper.date_of_record.year
    is_tax_credit_btn_enabled = TimeKeeper.date_of_record < Date.new(current_year, 11, HbxProfile::IndividualEnrollmentDueDayOfMonth + 1)
    allow(TimeKeeper).to receive(:date_of_record).and_return(Date.new(current_year, 10, 5)) unless is_tax_credit_btn_enabled
  end

  def create_family_faa_application(state)
    @user = FactoryBot.create(:user)
    @user.identity_response_code = 'acc'
    @user.identity_final_decision_code = "acc"
    @user.save
    @person = FactoryBot.create(:person, :with_consumer_role, user: user)
    family = FactoryBot.create(:family, :with_primary_family_member, person: @person)
    @application = FactoryBot.create(:financial_assistance_application, aasm_state: state, family_id: family.id, effective_date: TimeKeeper.date_of_record)
  end

  def create_family_faa_application_with_applicants(state)
    create_family_faa_application(state)
    eligibility_determination1 = FactoryBot.create(:financial_assistance_eligibility_determination, application: @application)
    FactoryBot.create(:financial_assistance_applicant, eligibility_determination_id: eligibility_determination1.id, is_primary_applicant: true, gender: "male", application: @application, family_member_id: BSON::ObjectId.new)
    @application.applicants.each do |appl|
      appl.addresses = [FactoryBot.build(:financial_assistance_address,
                                         :address_1 => '1111 Awesome Street NE',
                                         :address_2 => '#111',
                                         :address_3 => '',
                                         :city => 'Washington',
                                         :country_name => '',
                                         :kind => 'home',
                                         :state => FinancialAssistanceRegistry[:enroll_app].setting(:state_abbreviation).item,
                                         :zip => '20001',
                                         county: 'Cumberland')]
      appl.save!
    end
    @application.save!
  end

  def create_family_faa_application_with_applicants_and_evidences(state)
    create_family_faa_application_with_applicants(state)

    @application.applicants.each do |applicant|
      applicant.income_evidence = FactoryBot.build(:evidence, :with_request_results, :with_verification_histories, key: :income, title: 'Income', aasm_state: 'pending', is_satisfied: false)
      applicant.esi_evidence = FactoryBot.build(:evidence, :with_request_results, :with_verification_histories, key: :esi_mec, title: 'ESI MEC')
      applicant.non_esi_evidence = FactoryBot.build(:evidence, :with_request_results, :with_verification_histories, key: :non_esi_mec, title: 'Non ESI MEC')
      applicant.local_mec_evidence = FactoryBot.build(:evidence, :with_request_results, :with_verification_histories, key: :local_mec, title: 'Local MEC')
      applicant.save
    end
  end

  def create_enrollment_for_family(family, carrier_name = nil)
    if carrier_name == 'Kaiser'
      enrollment_product = create_kaiser_product
    elsif carrier_name == 'Anthm'
      enrollment_product = create_anthm_product
    else
      enrollment_product = create_cat_product
    end
    enrollment = FactoryBot.create(:hbx_enrollment, :with_enrollment_members,
                                   :family => family,
                                   :household => family.active_household,
                                   :aasm_state => 'coverage_selected',
                                   :is_any_enrollment_member_outstanding => true,
                                   :kind => 'individual',
                                   :product => enrollment_product,
                                   :effective_on => TimeKeeper.date_of_record.beginning_of_year)
    family.family_members.each do |fm|
      FactoryBot.create(:hbx_enrollment_member, applicant_id: fm.id, eligibility_date: (TimeKeeper.date_of_record - 2.months), hbx_enrollment: enrollment)
    end
    enrollment.save!
    enrollment
  end
end

World(IvlAssistanceWorld)
