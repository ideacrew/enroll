# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitMarkets::Operations::BenefitSponsorCatalogs::Create, dbclean: :after_each do

  let!(:site) do
    FactoryBot.create(
      :benefit_sponsors_site, :with_benefit_market,
      :as_hbx_profile, EnrollRegistry[:enroll_app].setting(:site_key).item
    )
  end
  let(:benefit_market)          { site.benefit_markets.first }
  let(:service_area)            { create_default(:benefit_markets_locations_service_area) }
  let(:effective_date)          { TimeKeeper.date_of_record.next_month.beginning_of_month }
  let(:application_period)      { effective_date..(effective_date + 1.year).prev_day }
  let(:pricing_units)           { [{_id: BSON::ObjectId.new, name: 'name', display_name: 'Employee Only', order: 1}] }
  let(:premium_tuples)          { {_id: BSON::ObjectId.new, age: 12, cost: 227.07} }
  let(:effective_period)        { effective_date.beginning_of_year..effective_date.end_of_year }
  let(:premium_tables)          { [{_id: BSON::ObjectId.new, effective_period: effective_period, rating_area_id: BSON::ObjectId.new, premium_tuples: [premium_tuples]}] }
  let(:member_relationships)    { [{_id: BSON::ObjectId.new, relationship_name: :employee, relationship_kinds: [{}], age_threshold: 18, age_comparison: :==, disability_qualifier: true}] }
  let(:oe_start_on)             { TimeKeeper.date_of_record.beginning_of_month}
  let(:open_enrollment_period)  { oe_start_on..(oe_start_on + 10.days) }
  let(:probation_period_kinds)  { [] }

  let(:pricing_model) do
    {
      _id: BSON::ObjectId.new,
      name: 'name', price_calculator_kind: 'price_calculator_kind', pricing_units: pricing_units,
      product_multiplicities: [:product_multiplicities], member_relationships: member_relationships
    }
  end

  let(:contribution_unit) do
    {
      _id: BSON::ObjectId.new,
      name: "Employee",
      display_name: "Employee Only",
      order: 1,
      member_relationship_maps: [_id: BSON::ObjectId.new, relationship_name: :employee, operator: :==, count: 1]
    }
  end

  let(:contribution_model) do
    {
      _id: BSON::ObjectId.new,
      title: 'title', key: :key, sponsor_contribution_kind: 'sponsor_contribution_kind', contribution_calculator_kind: 'contribution_calculator_kind',
      many_simultaneous_contribution_units: true, product_multiplicities: [:product_multiplicities1, :product_multiplicities2],
      member_relationships: member_relationships, contribution_units: [contribution_unit]
    }
  end

  let(:product) do
    {
      _id: BSON::ObjectId.new,
      benefit_market_kind: :benefit_market_kind, application_period: application_period, kind: :kind,
      hbx_id: 'hbx_id', title: 'title', description: 'description', product_package_kinds: [:product_package_kinds],
      issuer_profile_id: BSON::ObjectId.new, premium_ages: 16..40, provider_directory_url: 'provider_directory_url',
      is_reference_plan_eligible: true, deductible: '123', family_deductible: '345', renewal_product_id: nil,
      issuer_assigned_id: 'issuer_assigned_id', service_area_id: BSON::ObjectId.new, network_information: 'network_information',
      nationwide: true, dc_in_network: false, sbc_document: nil, premium_tables: premium_tables
    }
  end

  let(:required_params) do
    {
      application_period: application_period, benefit_kind: :benefit_kind, product_kind: :product_kind, package_kind: :package_kind,
      title: 'Title', products: [product], contribution_model: contribution_model, contribution_models: [contribution_model],
      pricing_model: pricing_model, description: 'description', assigned_contribution_model: contribution_model
    }
  end

  let(:catalog_params) do
    {
      effective_date: effective_date,
      effective_period: application_period,
      open_enrollment_period: open_enrollment_period,
      probation_period_kinds: probation_period_kinds,
      product_packages: [product_package_entity],
      service_area_ids: [BSON::ObjectId.new]
    }
  end

  let(:product_package_entity)  { BenefitMarkets::Entities::ProductPackage.new(required_params)}
  let(:benefit_sponsor_catalog) { BenefitMarkets::Entities::BenefitSponsorCatalog.new(catalog_params) }
  let(:params)                  { {sponsor_catalog_params: benefit_sponsor_catalog.to_h.merge(product_packages: [product_package_entity])} }

  context 'sending required parameters' do

    it 'should create BenefitSponsorCatalog' do
      expect(subject.call(params).success?).to be_truthy
      expect(subject.call(params).success).to be_a BenefitMarkets::Entities::BenefitSponsorCatalog
    end
  end
end

