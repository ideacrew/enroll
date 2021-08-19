# frozen_string_literal: true

RSpec.shared_context "setup families enrollments", :shared_context => :metadata do

  let!(:hbx_profile) {FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period)}
  let!(:rating_area) do
    ::BenefitMarkets::Locations::RatingArea.rating_area_for(address_assisted, during: current_calender_date) || FactoryBot.create_default(:benefit_markets_locations_rating_area)
  end
  let!(:renewal_calender_date) { hbx_profile.benefit_sponsorship.renewal_benefit_coverage_period.start_on }
  let!(:renewal_calender_year) {renewal_calender_date.year}

  let!(:current_calender_date) { hbx_profile.benefit_sponsorship.current_benefit_coverage_period.start_on }
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
  let!(:service_area) do
    ::BenefitMarkets::Locations::ServiceArea.service_areas_for(address_assisted, during: current_calender_date).first || FactoryBot.create_default(:benefit_markets_locations_service_area)
  end
  let!(:renewal_rating_area) do
    ::BenefitMarkets::Locations::RatingArea.rating_area_for(address_assisted, during: renewal_calender_date) || FactoryBot.create_default(:benefit_markets_locations_rating_area, active_year: renewal_calender_date.year)
  end
  let!(:renewal_service_area) do
    ::BenefitMarkets::Locations::ServiceArea.service_areas_for(address_assisted, during: renewal_calender_date).first || FactoryBot.create_default(:benefit_markets_locations_service_area, active_year: renewal_calender_date.year)
  end

  let(:application_period) { current_calender_date.beginning_of_year..current_calender_date.end_of_year }
  let(:start_on) { current_calender_date }
  let(:address_assisted) { family_assisted.primary_person.rating_address }

  let!(:active_individual_health_product) do
    prod =
      FactoryBot.create(
        :benefit_markets_products_health_products_health_product,
        :with_issuer_profile,
        :silver,
        benefit_market_kind: :aca_individual,
        kind: :health,
        service_area: service_area,
        csr_variant_id: '01',
        renewal_product_id: renewal_individual_health_product.id
      )
    prod.premium_tables = [premium_table]
    prod.save
    prod
  end
  let(:premium_table)        { build(:benefit_markets_products_premium_table, effective_period: application_period, rating_area: rating_area) }

  let!(:active_csr_87_product) do
    csr_product = FactoryBot.create(
      :active_csr_87_product,
      service_area: service_area,
      renewal_product: renewal_csr_87_product,
      application_period: application_period
    )
    csr_product.premium_tables = [csr_premium_table]
    csr_product.hios_base_id = csr_product.hios_id.split("-").first
    csr_product.save
    csr_product
  end
  let(:csr_premium_table)        { build(:benefit_markets_products_premium_table, effective_period: application_period, rating_area: rating_area) }

  let(:renewal_application_period) { renewal_calender_date.beginning_of_year..renewal_calender_date.end_of_year }
  let!(:renewal_individual_health_product) do
    prod =
      FactoryBot.create(
        :benefit_markets_products_health_products_health_product,
        :with_issuer_profile,
        :silver,
        benefit_market_kind: :aca_individual,
        kind: :health,
        service_area: renewal_service_area,
        csr_variant_id: '01',
        application_period: renewal_application_period
      )
    prod.premium_tables = [renewal_individual_premium_table]
    prod.save
    prod
  end

  let(:renewal_individual_premium_table) { build(:benefit_markets_products_premium_table, effective_period: renewal_application_period, rating_area: renewal_rating_area) }

  let!(:renewal_csr_87_product) do
    csr_product = FactoryBot.create(
      :renewal_csr_87_product,
      service_area: renewal_service_area,
      application_period: renewal_application_period
    )
    csr_product.premium_tables = [renewal_csr_premium_table]
    csr_product.hios_base_id = csr_product.hios_id.split("-").first
    csr_product.save
    csr_product
  end
  let!(:renewal_csr_premium_table)        { build(:benefit_markets_products_premium_table, effective_period: renewal_application_period, rating_area: renewal_rating_area) }

  before do
    renewal_individual_health_product.update_attributes!(hios_id: active_individual_health_product.hios_id,
                                                         hios_base_id: active_individual_health_product.hios_base_id)

    renewal_csr_87_product.update_attributes!(hios_id: active_csr_87_product.hios_id,
                                              hios_base_id: active_csr_87_product.hios_base_id)
  end
end
