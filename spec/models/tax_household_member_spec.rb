# frozen_string_literal: true

require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/support/benefit_sponsors_site_spec_helpers.rb"

RSpec.describe TaxHouseholdMember, type: :model do
  before :all do
    DatabaseCleaner.clean
  end

  let!(:person) {FactoryBot.create(:person, :with_family, dob: Date.new(TimeKeeper.date_of_record.year, 0o1, 0o1))}
  let!(:household) {FactoryBot.create(:household, family: person.primary_family)}
  let!(:tax_household) {FactoryBot.create(:tax_household, household: household)}
  let!(:tax_household_member1) {tax_household.tax_household_members.build(applicant_id: person.primary_family.family_members.first.id)}
  let!(:eligibility_kinds1) {{"is_ia_eligible" => "true", "is_medicaid_chip_eligible" => "true"}}
  let!(:eligibility_kinds2) {{"is_ia_eligible" => "true", "is_medicaid_chip_eligible" => "false"}}
  let!(:eligibility_kinds3) {{"is_ia_eligible" => "false", "is_medicaid_chip_eligible" => "false"}}

  context "update_eligibility_kinds" do
    it "should not update and return false when trying to update both the eligibility_kinds as true" do
      expect(tax_household_member1.update_eligibility_kinds(eligibility_kinds1)).to eq false
    end

    it "should update and return true when trying to update eligibility_kinds other than true for both the fields respectively" do
      expect(tax_household_member1.update_eligibility_kinds(eligibility_kinds2)).to eq true
    end

    it "should have respective data after updating is_ia_eligible & is_medicaid_chip_eligible" do
      tax_household_member1.update_eligibility_kinds(eligibility_kinds3)
      expect(tax_household_member1.is_ia_eligible).to eq false
      expect(tax_household_member1.is_medicaid_chip_eligible).to eq false
    end
  end

  context 'for csr_eligibility_kind' do
    shared_examples_for 'ensures csr_eligibility_kind field value' do |csr_percent_as_integer, csr_eligibility_kind|
      before do
        @tax_household_member2 = tax_household.tax_household_members.build(applicant_id: person.primary_family.family_members.first.id, csr_percent_as_integer: csr_percent_as_integer)
      end

      it 'should match with expected csr_eligibility_kind for given csr_percent_as_integer' do
        expect(@tax_household_member2.csr_eligibility_kind).to eq(csr_eligibility_kind)
      end
    end

    context 'a valid csr_percent_as_integer' do
      it_behaves_like 'ensures csr_eligibility_kind field value', 100, 'csr_100'
      it_behaves_like 'ensures csr_eligibility_kind field value', 94, 'csr_94'
      it_behaves_like 'ensures csr_eligibility_kind field value', 87, 'csr_87'
      it_behaves_like 'ensures csr_eligibility_kind field value', 73, 'csr_73'
      it_behaves_like 'ensures csr_eligibility_kind field value', 0, 'csr_0'
      it_behaves_like 'ensures csr_eligibility_kind field value', -1, 'csr_limited'
    end
  end

  context "age_on_effective_date" do

    before { person.reload }

    it "should return current age for coverage start on month is equal to dob month" do
      tax_household_member1.person.update_attributes(dob: Date.new(TimeKeeper.date_of_record.year, TimeKeeper.date_of_record.month, TimeKeeper.date_of_record.day))
      age = TimeKeeper.date_of_record.year - person.dob.year
      expect(tax_household_member1.age_on_effective_date).to eq age
    end

    it "should return age-1 for coverage start on month is less than dob month" do
      tax_household_member1.person.update_attributes(dob: Date.new(TimeKeeper.date_of_record.year, TimeKeeper.date_of_record.month, TimeKeeper.date_of_record.day) + 1.day)
      age = TimeKeeper.date_of_record.year - person.dob.year
      expect(tax_household_member1.age_on_effective_date).to eq age - 1
    end

    it "should return age-1 for coverage start on day is less to dob day" do
      tax_household_member1.person.update_attributes(dob: Date.new(TimeKeeper.date_of_record.year, TimeKeeper.date_of_record.month, TimeKeeper.date_of_record.day) + 1.month)
      age = TimeKeeper.date_of_record.year - person.dob.year
      expect(tax_household_member1.age_on_effective_date).to eq age - 1
    end
  end

  context "#aptc_benchmark_amount", dbclean: :after_each do
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
    let(:enrollment) {FactoryBot.create(:hbx_enrollment, family: family, product: product, effective_on: TimeKeeper.date_of_record)}
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
    let!(:household) { FactoryBot.create(:household, family: family) }

    before do
      ::BenefitMarkets::Products::ProductRateCache.initialize_rate_cache!
      ::BenefitMarkets::Products::ProductFactorCache.initialize_factor_cache!
    end

    it 'should return valid benchmark value' do
      expect(tax_household_member1.aptc_benchmark_amount(enrollment)).to eq 198.86
      expect(tax_household_member1.aptc_benchmark_amount(enrollment, Date.new(TimeKeeper.date_of_record.year, 1, 1))).to eq 198.86
    end
  end

  context 'adding member_determinations' do
    let(:override_rules) {::AcaEntities::MagiMedicaid::Types::EligibilityOverrideRule.values}
    let(:member_determinations) do
      [medicaid_and_chip_member_determination]
    end

    let(:medicaid_and_chip_member_determination) do
      {
        kind: 'Medicaid/CHIP Determination',
        criteria_met: false,
        determination_reasons: [],
        eligibility_overrides: medicaid_chip_eligibility_overrides
      }
    end

    let(:medicaid_chip_eligibility_overrides) do
      override_rules.map do |rule|
        {
          override_rule: rule,
          override_applied: false
        }
      end
    end

    before do
      tax_household_member1.update(member_determinations: member_determinations)
    end

    it 'should successfully add all member determination attributes' do
      expect(tax_household_member1.member_determinations.first.kind).to eq('Medicaid/CHIP Determination')
      expect(tax_household_member1.member_determinations.first.criteria_met).to eq(false)
      expect(tax_household_member1.member_determinations.first.determination_reasons).to eq([])
      expect(tax_household_member1.member_determinations.first.eligibility_overrides.present?).to be_truthy
    end

    context 'eligibility_overrides' do
      it 'should successfully add all eligibility_overrides attributes' do
        override_rules.each do |rule|
          override = tax_household_member1.member_determinations.first.eligibility_overrides.detect{|o| o.override_rule == rule}
          expect(override.present?).to be_truthy
          expect(override.override_applied).to eq(false)
          expect(override.created_at.present?).to be_truthy
          expect(override.updated_at.present?).to be_truthy
        end
      end
    end
  end
end
