# frozen_string_literal: true

require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/support/benefit_sponsors_site_spec_helpers.rb"

RSpec.describe ::Operations::Products::DetermineSlcspForTaxHouseholdMember, dbclean: :after_each do

  it 'should be a container-ready operation' do
    expect(subject.respond_to?(:call)).to be_truthy
  end

  describe 'clients with county based rating area' do

    let(:site) do
      BenefitSponsors::SiteSpecHelpers.create_site_with_hbx_profile_and_empty_benefit_market
    end
    let!(:rating_area) do
      ::BenefitMarkets::Locations::RatingArea.rating_area_for(address, during: effective_on) || FactoryBot.create_default(:benefit_markets_locations_rating_area)
    end
    let!(:service_area) do
      ::BenefitMarkets::Locations::ServiceArea.service_areas_for(address, during: effective_on).first || FactoryBot.create_default(:benefit_markets_locations_service_area)
    end
    let(:application_period) { TimeKeeper.date_of_record.beginning_of_year..TimeKeeper.date_of_record.end_of_year }
    let(:effective_on) { TimeKeeper.date_of_record.beginning_of_month }
    let!(:product) do
      prod =
        FactoryBot.create(
          :benefit_markets_products_health_products_health_product,
          :with_issuer_profile,
          benefit_market_kind: :aca_individual,
          kind: :health,
          assigned_site: site,
          service_area: service_area,
          csr_variant_id: '01',
          metal_level_kind: 'silver',
          application_period: application_period
        )
      prod.premium_tables = [premium_table]
      prod.save
      prod
    end
    let(:premium_table)        { build(:benefit_markets_products_premium_table, effective_period: application_period, rating_area: rating_area) }

    let(:address) { person.rating_address }
    let!(:person2) do
      member = FactoryBot.create(:person, dob: (TimeKeeper.date_of_record - 40.years))
      person.ensure_relationship_with(member, 'spouse')
      member.save!
      member
    end
    let!(:family_member2) {FactoryBot.create(:family_member, family: family, person: person2)}
    let!(:tax_household) {FactoryBot.create(:tax_household, household: family.active_household, effective_ending_on: nil, effective_starting_on: effective_on)}
    let!(:tax_household_member1) {FactoryBot.create(:tax_household_member, applicant_id: family.family_members[0].id, tax_household: tax_household)}
    let!(:tax_household_member2) {FactoryBot.create(:tax_household_member, applicant_id: family.family_members[1].id, tax_household: tax_household)}
    let!(:eligibilty_determination) {FactoryBot.create(:eligibility_determination, max_aptc: 500.00, tax_household: tax_household, csr_eligibility_kind: 'csr_73')}
    let!(:person) { FactoryBot.create(:person, :with_consumer_role) }
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }

    let(:params) do
      {
        effective_date: effective_on,
        tax_household_member: tax_household_member1
      }
    end

    before do
      ::BenefitMarkets::Products::ProductRateCache.initialize_rate_cache!
    end

    it 'should return success' do
      result = subject.call(params)
      expect(result.success?).to eq true
    end

    it 'should return ehb premium amount for the member' do
      result = subject.call(params)
      expect(result.success[:cost]).to eq 198.86
    end

    it 'should return slscp for the member' do
      result = subject.call(params)
      expect(result.success[:product_id]).to eq product.id
    end
  end
end
