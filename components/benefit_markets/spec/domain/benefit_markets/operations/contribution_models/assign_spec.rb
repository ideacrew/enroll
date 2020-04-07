# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitMarkets::Operations::ContributionModels::Assign, dbclean: :after_each do

	let!(:site)                   { FactoryBot.create(:benefit_sponsors_site, :with_benefit_market, :with_benefit_market_catalog_and_product_packages, :as_hbx_profile, Settings.site.key) }
  let(:benefit_market)          { site.benefit_markets.first }
  let(:effective_date)          { TimeKeeper.date_of_record.next_month.beginning_of_month }
  let(:effective_period)        { effective_date.beginning_of_year..effective_date.end_of_year }
  let(:application_period)      { effective_date..(effective_date + 1.year).prev_day }
  let(:market_kind)             { :aca_shop }
  let(:service_areas)           { FactoryBot.create(:benefit_markets_locations_service_area).to_a }
  let(:pricing_units)           { [{name: 'name', display_name: 'Employee Only', order: 1}] }
  let(:premium_tuples)          { {age: 12, cost: 227.07} }
  let(:premium_tables)          { [{effective_period: effective_period, rating_area_id: BSON::ObjectId.new, premium_tuples: [premium_tuples]}] }
  let(:member_relationships)    { [{relationship_name: :employee, relationship_kinds: ['self'], age_threshold: 18, age_comparison: :==, disability_qualifier: true}] }
  let(:oe_start_on)             { TimeKeeper.date_of_record.beginning_of_month}
  let(:open_enrollment_period)  { oe_start_on..(oe_start_on + 10.days) }

  let(:pricing_model) do
    {
      name: 'name', price_calculator_kind: 'price_calculator_kind', pricing_units: pricing_units,
      product_multiplicities: [:product_multiplicities], member_relationships: member_relationships
    }
  end

  let(:contribution_unit) do
    {
      name: "Employee",
      display_name: "Employee Only",
      order: 1,
      member_relationship_maps: [relationship_name: :employee, operator: :==, count: 1]
    }
  end

  let(:contribution_model) do
    ::BenefitMarkets::Entities::ContributionModel.new({
      title: 'title', key: :zero_percent_sponsor_fixed_percent_contribution_model, sponsor_contribution_kind: 'sponsor_contribution_kind',
      contribution_calculator_kind: 'contribution_calculator_kind', many_simultaneous_contribution_units: true,
      product_multiplicities: [:product_multiplicities1, :product_multiplicities2],
      member_relationships: member_relationships, contribution_units: [contribution_unit]
    })
  end

  let(:sbc_document) do
    {
      title: 'title', creator: 'creator', publisher: 'publisher', format: 'file_format', language: 'language', type: 'type', source: 'source'
    }
  end

  let(:product_params) do
    {
      _id: BSON::ObjectId.new, hios_id: '9879', hios_base_id: '34985', metal_level_kind: :silver,
      ehb: 0.9, is_standard_plan: true, hsa_eligibility: true, csr_variant_id: '01', health_plan_kind: :pos,
      benefit_market_kind: :aca_shop, application_period: application_period, kind: :health,
      hbx_id: 'hbx_id', title: 'title', description: 'description', product_package_kinds: [:multi_product, :single_issuer],
      issuer_profile_id: BSON::ObjectId.new, premium_ages: 19..60, provider_directory_url: 'provider_directory_url',
      is_reference_plan_eligible: true, deductible: '123', family_deductible: '345', rx_formulary_url: 'rx_formulary_url',
      issuer_assigned_id: 'issuer_assigned_id', service_area_id: BSON::ObjectId.new, network_information: 'network_information',
      nationwide: true, dc_in_network: false, sbc_document: sbc_document, premium_tables: premium_tables
    }
  end

  let(:product_entity)          { BenefitMarkets::Entities::HealthProduct.new(product_params) }
  let(:product_package_params) do
    {
      application_period: application_period, benefit_kind: :benefit_kind, product_kind: :product_kind, package_kind: :package_kind,
      title: 'Title', products: [product_entity], contribution_model: contribution_model.to_h, contribution_models: [contribution_model],
      pricing_model: pricing_model, description: 'description'
    }
  end

  let(:enrollment_eligibility_initial)  { double(effective_date: effective_date, market_kind: market_kind, benefit_application_kind: :initial, service_areas: service_areas) }
  let(:params)                 {{ product_package_values: product_package_params, enrollment_eligibility: enrollment_eligibility_initial }}


  context 'sending required parameters' do
    it 'should assign ContributionModel for initial' do
    	result = subject.call(params)
      expect(result.success?).to be_truthy
      key = result.success[:product_package_values][:assigned_contribution_model].key

      # if effective_date.month == 1
      # 	expect(key).to eq (:zero_percent_sponsor_fixed_percent_contribution_model)
      # else
      # 	expect(key).to eq (:zero_percent_sponsor_fixed_percent_contribution_model)
      # end
    end
  end

  context 'sending required parameters' do
  	let(:enrollment_eligibility_renewal)  { double(effective_date: effective_date, market_kind: market_kind, benefit_application_kind: :renewal, service_areas: service_areas) }

    it 'should assign ContributionModel for renewal' do
    	result = subject.call(params)
      expect(result.success?).to be_truthy
      key = result.success[:product_package_values][:assigned_contribution_model].key

    #   if effective_date.month == 1
    #   	expect(key).to eq (:zero_percent_sponsor_fixed_percent_contribution_model)
    #   else
    #   	expect(key).to eq (:fifty_percent_sponsor_fixed_percent_contribution_model)
    #   end
    end
  end
end
