# frozen_string_literal: true

RSpec.shared_context 'family with 2 family members', :shared_context => :metadata do
  let(:person1_age) { 17 }
  let(:person2_age) { 16 }
  let(:start_of_year) { TimeKeeper.date_of_record.beginning_of_year }
  let(:person1) do
    per = FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role, dob: start_of_year - person1_age.years)
    per.rating_address.update_attributes!(county: 'York', zip: '04001', state: 'ME')
    per
  end
  let(:person2) do
    per = FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role, dob: start_of_year - person2_age.years)
    person1.ensure_relationship_with(per, 'spouse')
    per
  end
  let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person1) }
  let(:family_member1) { family.primary_applicant }
  let(:family_member2) { FactoryBot.create(:family_member, family: family, person: person2) }
end

RSpec.shared_context 'family with 5 family members', :shared_context => :metadata do
  let(:person1_age) { 30 }
  let(:person2_age) { 16 }
  let(:person3_age) { 14 }
  let(:person4_age) { 12 }
  let(:person5_age) { 2 }

  let(:start_of_year) { TimeKeeper.date_of_record.beginning_of_year }
  let(:person1) do
    per = FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role, dob: start_of_year - person1_age.years)
    per.rating_address.update_attributes!(county: 'York', zip: '04001', state: 'ME')
    per
  end
  let(:person2) do
    per = FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role, dob: start_of_year - person2_age.years)
    person1.ensure_relationship_with(per, 'child')
    per
  end
  let(:person3) do
    per = FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role, dob: start_of_year - person3_age.years)
    person1.ensure_relationship_with(per, 'child')
    per
  end
  let(:person4) do
    per = FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role, dob: start_of_year - person4_age.years)
    person1.ensure_relationship_with(per, 'child')
    per
  end
  let(:person5) do
    per = FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role, dob: start_of_year - person5_age.years)
    person1.ensure_relationship_with(per, 'child')
    per
  end

  let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person1) }
  let(:family_member1) { family.primary_applicant }
  let(:family_member2) { FactoryBot.create(:family_member, family: family, person: person2) }
  let(:family_member3) { FactoryBot.create(:family_member, family: family, person: person3) }
  let(:family_member4) { FactoryBot.create(:family_member, family: family, person: person4) }
  let(:family_member5) { FactoryBot.create(:family_member, family: family, person: person5) }

  let!(:county_zip) { ::BenefitMarkets::Locations::CountyZip.create!(county_name: 'York', zip: '04001', state: 'ME') }
  let!(:rating_area) do
    ::BenefitMarkets::Locations::RatingArea.create!(active_year: TimeKeeper.date_of_record.year, exchange_provided_code: "R-ME001", county_zip_ids: [county_zip.id])
  end
  let!(:service_area) do
    ::BenefitMarkets::Locations::ServiceArea.create!(active_year: TimeKeeper.date_of_record.year, county_zip_ids: [county_zip.id], issuer_provided_code: "MES002", issuer_profile_id: BSON::ObjectId.new)
  end
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
  let(:covers_pediatric_dental) { false }
  let!(:health_products) do
    [
      ['48396ME0860009', false],
      ['48396ME0860011', covers_pediatric_dental],
      ['48396ME0860013', false]
    ].each_with_index do |hios_id_covers_pediatric_dental, index|
      hios_id = hios_id_covers_pediatric_dental[0]
      health_pro = FactoryBot.create(
        :benefit_markets_products_health_products_health_product,
        :silver,
        csr_variant_id: '01',
        hios_id: hios_id,
        hios_base_id: hios_id,
        service_area_id: service_area.id,
        ehb: 1.0
      )
      health_pro.premium_tables.each do |pre_t|
        pre_t.update_attributes(rating_area_id: rating_area.id)
        next if index.zero?
        cost = index == 1 ? 600.00 : 590.00
        pre_t.premium_tuples.each do |pt|
          pt.update_attributes(cost: cost)
        end
      end

      qhp = create_qhp('NA', health_pro, hios_id)
      # 200.00, 500.00, 600.00 Health
      # 200.00, 400.00, 600.00 Dental
      next unless hios_id_covers_pediatric_dental[1]
      ['Dental Check-Up for Children', 'Basic Dental Care - Child', 'Major Dental Care - Child'].each do |benefit_type_code|
        qhp.qhp_benefits.create(benefit_type_code: benefit_type_code, is_benefit_covered: 'Covered')
      end
    end
  end

  let!(:dental_products) do
    [
      ['48396ME0860003', 'Allows Adult and Child-Only', 'Age-Based Rates'],
      ['48396ME0860005', 'Allows Child-Only', 'Age-Based Rates'],
      ['48396ME0860007', 'Allows Adult and Child-Only', 'Family-Tier Rates']
    ].each_with_index do |hios_id_child_only_offering_rating_method, index|
      hios_id = hios_id_child_only_offering_rating_method[0]
      child_only_offering = hios_id_child_only_offering_rating_method[1]
      rating_method = hios_id_child_only_offering_rating_method[2]
      dental_pro = FactoryBot.create(
        :benefit_markets_products_dental_products_dental_product,
        :ivl_product,
        hios_id: hios_id,
        hios_base_id: hios_id,
        rating_method: rating_method,
        service_area_id: service_area.id,
        ehb_apportionment_for_pediatric_dental: 1.0
      )
      dental_pro.premium_tables.each do |pre_t|
        pre_t.update_attributes(rating_area_id: rating_area.id)
        pre_t.premium_tuples.each { |pt| pt.update_attributes(cost: (pt.cost * index.next)) } unless index.zero?
      end
      create_qhp(child_only_offering, dental_pro, hios_id)
    end
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
    qhp
  end
end
