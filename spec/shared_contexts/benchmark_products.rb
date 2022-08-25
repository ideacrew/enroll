# frozen_string_literal: true

RSpec.shared_context 'family with 2 family members', :shared_context => :metadata do
  let(:start_of_year) { TimeKeeper.date_of_record.beginning_of_year }
  let(:person1) do
    per = FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role)
    per.rating_address.update_attributes!(county: 'York', zip: '04001', state: 'ME')
    per
  end
  let(:person2) do
    per = FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role, dob: start_of_year - 15.years)
    person1.ensure_relationship_with(per, 'spouse')
    per
  end
  let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person1) }
  let(:family_member1) { family.primary_applicant }
  let(:family_member2) { FactoryBot.create(:family_member, family: family, person: person2) }
end

RSpec.shared_context 'family with 2 family members with county_zip, rating_area & service_area', :shared_context => :metadata do
  include_context 'family with 2 family members'

  let!(:county_zip) { ::BenefitMarkets::Locations::CountyZip.create!(county_name: 'York', zip: '04001', state: 'ME') }
  let!(:rating_area) do
    ::BenefitMarkets::Locations::RatingArea.create!(active_year: TimeKeeper.date_of_record.year, exchange_provided_code: "R-ME001", county_zip_ids: [county_zip.id])
  end
  let!(:service_area) do
    ::BenefitMarkets::Locations::ServiceArea.create!(active_year: TimeKeeper.date_of_record.year, county_zip_ids: [county_zip.id], issuer_provided_code: "MES002", issuer_profile_id: BSON::ObjectId.new)
  end
end

RSpec.shared_context '3 dental products with different rating_methods, different child_only_offerings and 3 health products', :shared_context => :metadata do
  include_context 'family with 2 family members with county_zip, rating_area & service_area'

  let!(:health_products) do
    create_health_product('48396ME0860009')
    create_health_product('48396ME0860011')
    create_health_product('48396ME0860013')
  end

  def create_health_product(hios_id)
    health_pro = FactoryBot.create(
      :benefit_markets_products_health_products_health_product,
      :silver,
      hios_id: hios_id,
      hios_base_id: hios_id,
      service_area_id: service_area.id
    )
    health_pro.premium_tables.each do |pre_t|
      pre_t.update_attributes(rating_area_id: rating_area.id)
    end
    create_qhp('NA', health_pro, hios_id)
  end

  let!(:dental_products) do
    create_dental_product('48396ME0860003', 'Allows Child-Only', 'Age-Based Rates')
    create_dental_product('48396ME0860005', 'Allows Adult and Child-Only', 'Age-Based Rates')
    create_dental_product('48396ME0860007', 'Allows Adult and Child-Only', 'Family-Tier Rates')
  end

  def create_dental_product(hios_id, child_only_offering, rating_method)
    dental_pro = FactoryBot.create(
      :benefit_markets_products_dental_products_dental_product,
      :ivl_product,
      hios_id: hios_id,
      hios_base_id: hios_id,
      rating_method: rating_method,
      service_area_id: service_area.id
    )
    dental_pro.premium_tables.each do |pre_t|
      pre_t.update_attributes(rating_area_id: rating_area.id)
    end
    create_qhp(child_only_offering, dental_pro, hios_id)
  end

  def create_qhp(child_only_offering, product, hios_id)
    qhp = ::Products::Qhp.create(
      {
        issuer_id: "1234", state_postal_code: "ME",
        active_year: product.application_period.min.year,
        standard_component_id: product.hios_base_id,
        plan_marketing_name: "gold plan", hios_product_id: "1234",
        network_id: "123", service_area_id: service_area.id, formulary_id: "123",
        is_new_plan: "yes", plan_type: "test", metal_level: "bronze",
        unique_plan_design: "", qhp_or_non_qhp: "qhp",
        insurance_plan_pregnancy_notice_req_ind: "yes",
        is_specialist_referral_required: "yes", hsa_eligibility: "yes",
        emp_contribution_amount_for_hsa_or_hra: "1000", child_only_offering: child_only_offering,
        is_wellness_program_offered: "yes", plan_effective_date: "04/01/2015".to_date,
        out_of_country_coverage: "yes", out_of_service_area_coverage: "yes",
        national_network: "yes", summary_benefit_and_coverage_url: "www.example.com"
      }
    )
    qhp.qhp_premium_tables.create(
      { rate_area_id: rating_area.exchange_provided_code, plan_id: hios_id,
        age_number: 0, primary_enrollee: 39.0, couple_enrollee: 72.5,
        couple_enrollee_one_dependent: 105.5, couple_enrollee_two_dependent: 138.5,
        couple_enrollee_many_dependent: 171.0, primary_enrollee_one_dependent: 77.5,
        primary_enrollee_two_dependent: 115.5, primary_enrollee_many_dependent: 153.0 }
    )
  end
end
