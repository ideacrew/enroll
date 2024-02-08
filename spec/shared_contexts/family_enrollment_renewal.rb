# frozen_string_literal: true

RSpec.shared_context "setup family initial and renewal enrollments data", :shared_context => :metadata do
  let(:current_date) { Date.new(calender_year, 11, 1) }
  let(:current_benefit_coverage_period) { OpenStruct.new(start_on: current_date.beginning_of_year, end_on: current_date.end_of_year) }
  let(:renewal_benefit_coverage_period) { OpenStruct.new(start_on: current_date.next_year.beginning_of_year, end_on: current_date.next_year.end_of_year) }
  let(:aptc_values) {{}}
  let(:assisted) { nil }
  let(:primary) { FactoryBot.create(:person, :with_consumer_role, dob: primary_dob, is_tobacco_user: 'y') }

  let!(:family) do
    FactoryBot.create(:family, :with_primary_family_member, :person => primary)
  end

  let(:coverall_primary) { FactoryBot.create(:person, :with_resident_role, dob: primary_dob) }

  let!(:coverall_family) do
    FactoryBot.create(:family, :with_primary_family_member, :person => coverall_primary)
  end

  let(:spouse_person) { FactoryBot.create(:person, :with_consumer_role, dob: spouse_dob, is_tobacco_user: 'y') }

  let!(:spouse) { FactoryBot.create(:family_member, person: spouse_person, family: family) }

  let(:person_child1) { FactoryBot.create(:person, :with_consumer_role, dob: child1_dob) }

  let!(:child1) { FactoryBot.create(:family_member, person: person_child1, family: family) }

  let(:person_child2) { FactoryBot.create(:person, :with_consumer_role, dob: child2_dob) }

  let!(:child2) { FactoryBot.create(:family_member, person: person_child2, family: family) }

  let(:person_child3) { FactoryBot.create(:person, :with_consumer_role, dob: child3_dob) }

  let!(:child3) { FactoryBot.create(:family_member, person: person_child3, family: family) }

  let(:primary_dob){ current_date.next_month - 57.years }
  let(:spouse_dob) { current_date.next_month - 55.years }
  let(:child1_dob) { current_date.next_month - 26.years }
  let(:child2_dob) { current_date.next_month - 20.years }
  let(:child3_dob) { current_benefit_coverage_period.start_on + 2.months - 25.years}

  let!(:enrollment) do
    FactoryBot.create(:hbx_enrollment,
                      :with_enrollment_members,
                      family: family,
                      enrollment_members: enrollment_members,
                      household: family.active_household,
                      coverage_kind: coverage_kind,
                      effective_on: current_benefit_coverage_period.start_on,
                      kind: "individual",
                      product_id: current_product.id,
                      rating_area_id: rating_area.id,
                      consumer_role_id: family.primary_person.consumer_role.id,
                      aasm_state: 'coverage_selected')
  end

  let!(:coverall_enrollment) do
    FactoryBot.create(:hbx_enrollment,
                      :with_enrollment_members,
                      family: coverall_family,
                      enrollment_members: coverall_enrollment_members,
                      household: coverall_family.active_household,
                      coverage_kind: coverage_kind,
                      rating_area_id: rating_area.id,
                      resident_role_id: coverall_family.primary_person.resident_role.id,
                      effective_on: current_benefit_coverage_period.start_on,
                      kind: "coverall",
                      product_id: current_product.id,
                      aasm_state: 'coverage_selected')
  end

  let!(:catastrophic_enrollment) do
    FactoryBot.create(:hbx_enrollment,
                      :with_enrollment_members,
                      family: family,
                      enrollment_members: enrollment_members,
                      household: family.active_household,
                      coverage_kind: coverage_kind,
                      rating_area_id: rating_area.id,
                      resident_role_id: family.primary_person.consumer_role.id,
                      effective_on: Date.new(Date.current.year,1,1),
                      kind: "coverall",
                      product_id: current_cat_product.id,
                      aasm_state: 'coverage_selected')
  end

  let(:enrollment_members) { family.family_members }
  let(:coverall_enrollment_members) { coverall_family.family_members }
  let(:calender_year) { TimeKeeper.date_of_record.year }
  let(:coverage_kind) { 'health' }
  let!(:rating_area) do
    ::BenefitMarkets::Locations::RatingArea.rating_area_for(address, during: start_on) || FactoryBot.create_default(:benefit_markets_locations_rating_area)
  end

  let!(:service_area) do
    ::BenefitMarkets::Locations::ServiceArea.service_areas_for(address, during: start_on).first || FactoryBot.create_default(:benefit_markets_locations_service_area)
  end

  let!(:renewal_rating_area) do
    ::BenefitMarkets::Locations::RatingArea.rating_area_for(address, during: start_on.next_year) || FactoryBot.create_default(:benefit_markets_locations_rating_area, active_year: start_on.next_year.year)
  end

  let!(:renewal_service_area) do
    ::BenefitMarkets::Locations::ServiceArea.service_areas_for(address, during: start_on.next_year).first || FactoryBot.create_default(:benefit_markets_locations_service_area, active_year: start_on.next_year.year)
  end

  let(:start_on) { current_benefit_coverage_period.start_on }
  let(:address) { family.primary_person.rating_address }
  let(:application_period) { start_on.beginning_of_year..start_on.end_of_year }
  let(:renewal_application_period) { start_on.beginning_of_year.next_year..start_on.end_of_year.next_year}

  let!(:current_product) do
    prod =
      FactoryBot.create(
        :benefit_markets_products_health_products_health_product,
        :with_issuer_profile,
        benefit_market_kind: :aca_individual,
        kind: :health,
        service_area: service_area,
        csr_variant_id: '01',
        metal_level_kind: 'silver',
        hios_id: '11111111122302-01',
        renewal_product_id: renewal_product.id,
        application_period: application_period
      )
    prod.premium_tables = [premium_table]
    prod.save
    prod
  end

  let!(:current_dental_product) do
    prod =
    FactoryBot.create(:benefit_markets_products_dental_products_dental_product,
      :with_renewal_product,
      application_period: application_period,
      product_package_kinds: [:single_product],
      service_area: service_area,
      renewal_service_area: renewal_service_area,
      metal_level_kind: :dental
    )
    prod
  end

  let(:premium_table)        { build(:benefit_markets_products_premium_table, effective_period: application_period, rating_area: rating_area) }

  let!(:renewal_product) do
    prod =
      FactoryBot.create(
        :benefit_markets_products_health_products_health_product,
        :with_issuer_profile,
        benefit_market_kind: :aca_individual,
        kind: :health,
        service_area: renewal_service_area,
        csr_variant_id: '01',
        metal_level_kind: 'silver',
        hios_id: '11111111122302-01',
        application_period: renewal_application_period
      )
    prod.premium_tables = [renewal_premium_table]
    prod.save
    prod
  end

  let(:renewal_premium_table)        { build(:benefit_markets_products_premium_table, effective_period: renewal_application_period, rating_area: renewal_rating_area) }

  let!(:current_cat_product) do
    prod =
      FactoryBot.create(
        :active_ivl_silver_health_product,
        :with_issuer_profile,
        benefit_market_kind: :aca_individual,
        kind: :health,
        service_area: service_area,
        csr_variant_id: '01',
        metal_level_kind: :catastrophic,
        hios_base_id: "94506DC0390008",
        application_period: application_period
      )
    prod.premium_tables = [cat_premium_table]
    prod.save
    prod
  end

  let(:cat_premium_table)        { build(:benefit_markets_products_premium_table, effective_period: application_period, rating_area: rating_area) }
end
