# frozen_string_literal: true

FactoryBot.define do
  factory :benefit_markets_products_health_products_health_product, class: 'BenefitMarkets::Products::HealthProducts::HealthProduct' do

    benefit_market_kind  { :aca_individual }
    application_period   { Date.new(Date.today.year, 1, 1)..Date.new(Date.today.year, 12, 31) }
    sequence(:hbx_id)    { |n| n + 12_345 }

    sequence(:title)     { |n| "#{issuer_name} #{metal_level_kind}#{n} 2,000" }
    description          { "Highest rated and highest value" }
    health_plan_kind     { :pos }
    ehb                  { 0.9943 }
    metal_level_kind     { BenefitMarkets::Products::HealthProducts::HealthProduct::METAL_LEVEL_KINDS.sample }
    dc_in_network        { true }
    nationwide           { true }
    deductible           { "$500 per person" }
    family_deductible    { "$500 per person | $1000 per group" }
    is_hc4cc_plan        { false }
    csr_variant_id       { "04" }

    product_package_kinds { [:single_product, :single_issuer, :metal_level] }
    sequence(:hios_id, (10..99).cycle)  { |n| "41842DC04000#{n}-01" }
    hios_base_id          { hios_id.split('-')[0] }

    transient do
      build_premium_tables true
      issuer_name { 'BlueChoice' }
    end

    trait :ivl_product do
      benefit_market_kind  { :aca_individual }
    end

    trait :next_year do
      application_period do
        year = Time.zone.today.next_year.year
        Date.new(year, 1, 1)..Date.new(year, 12, 31)
      end
    end

    trait :csr_87 do
      metal_level_kind        { :silver }
      benefit_market_kind     { :aca_individual }
      csr_variant_id          { "87" }
    end

    trait :csr_00 do
      metal_level_kind        { :silver }
      benefit_market_kind     { :aca_individual }
      csr_variant_id          { "00" }
    end

    trait :catastrophic do
      kind                { :health }
      metal_level_kind    { :catastrophic }
      benefit_market_kind { :aca_individual }
    end

    trait :gold do
      kind                { :health }
      metal_level_kind    { :gold }
      benefit_market_kind { :aca_individual }
    end

    trait :bronze do
      kind                { :health }
      metal_level_kind    { :bronze }
      benefit_market_kind { :aca_individual }
    end

    trait :platinum do
      kind                { :health }
      metal_level_kind    { :platinum }
      benefit_market_kind { :aca_individual }
    end

    trait :silver do
      kind                { :health }
      metal_level_kind    { :silver }
      benefit_market_kind { :aca_individual }
    end

    trait :with_issuer_profile do
      transient do
        assigned_site { nil }
      end

      issuer_profile { create(:benefit_sponsors_organizations_issuer_profile, assigned_site: assigned_site, abbrev: 'BCBS') }
    end

    trait :with_issuer_profile_kaiser do
      issuer_profile { create(:benefit_sponsors_organizations_issuer_profile, :kaiser_profile) }
    end


    # association :service_area, factory: :benefit_markets_locations_service_area, strategy: :create

  end
end
