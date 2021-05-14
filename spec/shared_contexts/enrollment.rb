# frozen_string_literal: true

RSpec.shared_context "setup families enrollments", :shared_context => :metadata do

  let!(:hbx_profile) {FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period)}
  let!(:rating_area) { FactoryBot.create(:benefit_markets_locations_rating_area) }
  let!(:renewal_calender_date) {HbxProfile.current_hbx.benefit_sponsorship.renewal_benefit_coverage_period.start_on}
  let!(:renewal_calender_year) {renewal_calender_date.year}

  let!(:current_calender_date) {HbxProfile.current_hbx.benefit_sponsorship.current_benefit_coverage_period.start_on}
  let!(:current_calender_year) {current_calender_date.year}
  let!(:family_unassisted) {FactoryBot.create(:individual_market_family)}
  let!(:enrollment_unassisted) do
    FactoryBot.create(:hbx_enrollment, :individual_unassisted, :with_enrollment_members,
                      family: family_unassisted,
                      household: family_unassisted.active_household,
                      enrollment_members: [family_unassisted.family_members.first],
                      rating_area_id: rating_area.id,
                      consumer_role_id: family_unassisted.primary_family_member.person.consumer_role.id,
                      product: active_individual_health_product, effective_on: current_calender_date)
  end
  let!(:renewal_enrollment_unassisted) do
    FactoryBot.create(:hbx_enrollment, :individual_unassisted, :with_enrollment_members,
                      family: family_unassisted,
                      aasm_state: "renewing_coverage_selected",
                      household: family_unassisted.active_household,
                      rating_area_id: rating_area.id,
                      consumer_role_id: family_unassisted.primary_family_member.person.consumer_role.id,
                      enrollment_members: [family_unassisted.family_members.first],
                      product: active_individual_health_product, effective_on: current_calender_date)
  end

  let!(:family_assisted) {FactoryBot.create(:individual_market_family)}
  let!(:tax_household) do
    FactoryBot.create(:tax_household,
                      effective_starting_on: renewal_calender_date,
                      effective_ending_on: nil, household: family_assisted.active_household)
  end

  let!(:eligibility_determination1) {FactoryBot.create(:eligibility_determination, tax_household: tax_household, csr_percent_as_integer: 87)}
  let!(:tax_household_member1) do
    tax_household.tax_household_members.create(applicant_id: family_assisted.family_members.first.id,
                                               is_ia_eligible: true)
  end
  let!(:enrollment_assisted) do
    FactoryBot.create(:hbx_enrollment, :individual_assisted, :with_enrollment_members,
                      applied_aptc_amount: 110,
                      family: family_assisted,
                      rating_area_id: rating_area.id,
                      consumer_role_id: family_assisted.primary_family_member.person.consumer_role.id,
                      household: family_assisted.active_household,
                      enrollment_members: [family_assisted.family_members.first],
                      product: active_csr_87_product, effective_on: current_calender_date)
  end

  let!(:active_individual_health_product) do
    FactoryBot.create(:benefit_markets_products_health_products_health_product,
                      :silver,
                      csr_variant_id: '01',
                      renewal_product: renewal_individual_health_product)
  end

  let!(:active_csr_87_product) do
    FactoryBot.create(:active_csr_87_product, renewal_product: renewal_csr_87_product).tap do |product|
      product.hios_base_id = product.hios_id.split("-").first
    end
  end

  let!(:renewal_individual_health_product) do
    FactoryBot.create(:benefit_markets_products_health_products_health_product,
                      :silver,
                      :next_year,
                      csr_variant_id: '01')
  end

  let!(:renewal_csr_87_product) do
    FactoryBot.create(:renewal_csr_87_product).tap do |product|
      product.hios_base_id = product.hios_id.split("-").first
    end
  end

  before do
    renewal_individual_health_product.update_attributes!(hios_id: active_individual_health_product.hios_id,
                                                         hios_base_id: active_individual_health_product.hios_base_id)

    renewal_csr_87_product.update_attributes!(hios_id: active_csr_87_product.hios_id,
                                              hios_base_id: active_csr_87_product.hios_base_id)
  end
end
