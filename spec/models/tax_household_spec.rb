# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TaxHousehold, type: :model do
  let(:family)  { FactoryBot.create(:family) }

  before :each do
    allow(EnrollRegistry[:calculate_monthly_aggregate].feature).to receive(:is_enabled).and_return(false)
    allow(EnrollRegistry[:apply_aggregate_to_enrollment].feature).to receive(:is_enabled).and_return(false)
  end

  it "should have no people" do
    expect(subject.people).to be_empty
  end

  context "aptc_ratio_by_member" do
    let!(:plan) {FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, csr_variant_id: '01')}
    let(:current_hbx) {double(benefit_sponsorship: double(benefit_coverage_periods: [benefit_coverage_period]))}
    let(:benefit_coverage_period) {double(contains?: true, second_lowest_cost_silver_plan: plan)}
    let(:tax_household_member1) {double(is_ia_eligible?: true, age_on_effective_date: 28, applicant_id: 'tax_member1', benchmark_product_details_for: { product_id: plan.id })}
    let(:tax_household_member2) {double(is_ia_eligible?: true, age_on_effective_date: 26, applicant_id: 'tax_member2', benchmark_product_details_for: { product_id: plan.id })}

    it "can return ratio hash" do
      allow(HbxProfile).to receive(:current_hbx).and_return(current_hbx)
      tax_household = TaxHousehold.new(effective_starting_on: TimeKeeper.date_of_record)
      allow(tax_household).to receive(:aptc_members).and_return([tax_household_member1, tax_household_member2])
      expect(tax_household.aptc_ratio_by_member.class).to eq Hash
      result = {"tax_member1" => 0.5, "tax_member2" => 0.5}
      expect(tax_household.aptc_ratio_by_member).to eq result
    end
  end

  context "aptc_available_amount_by_member" do
    let!(:family) {create(:family, :with_primary_family_member_and_dependent)}
    let(:household) {create(:household, family: family)}
    let(:aptc_ratio_by_member) { {'member1' => 0.6, 'member2' => 0.4} }
    let(:hbx_member1) { double(applicant_id: 'member1', applied_aptc_amount: 20) }
    let(:hbx_member2) { double(applicant_id: 'member2', applied_aptc_amount: 10) }
    let(:hbx_enrollment) { double(applied_aptc_amount: 30, family: family, hbx_enrollment_members: [hbx_member1, hbx_member2]) }
    # let(:household) { family.active_household }

    it "can return result" do
      tax_household = TaxHousehold.new
      allow(tax_household).to receive(:household).and_return household
      allow(tax_household).to receive(:aptc_ratio_by_member).and_return aptc_ratio_by_member
      allow(tax_household).to receive(:current_max_aptc).and_return 100
      allow(tax_household).to receive(:effective_starting_on).and_return TimeKeeper.date_of_record
      allow(household).to receive(:hbx_enrollments_with_aptc_by_year).and_return([hbx_enrollment])
      expect(tax_household.aptc_available_amount_by_member(100.00).class).to eq Hash
      result = {'member1' => 40, 'member2' => 30}
      expect(tax_household.aptc_available_amount_by_member(100.00)).to eq result
    end
  end

  context "current_max_aptc" do
    before :each do
      @tax_household = TaxHousehold.new(effective_starting_on: TimeKeeper.date_of_record)
    end

    it "return max aptc when in the same year" do
      #allow(@tax_household).to receive(:latest_eligibility_determination).and_return(double(determined_at: TimeKeeper.date_of_record, max_aptc: 100))
      #expect(@tax_household.current_max_aptc).to eq 100
    end

    it "return 0 when not in the same year" do
      allow(@tax_household).to receive(:latest_eligibility_determination).and_return(double(determined_at: TimeKeeper.date_of_record + 1.year, max_aptc: 0))
      expect(@tax_household.current_max_aptc).to eq 0
    end
  end

  context "valid_csr_kind" do
    let!(:family) {create(:family, :with_primary_family_member_and_dependent)}
    let(:household) {create(:household, family: family)}
    let(:hbx_member1) { double(applicant_id: 'member1') }
    let(:hbx_member2) { double(applicant_id: 'member2') }
    let(:hbx_enrollment) { double(hbx_enrollment_members: [hbx_member1, hbx_member2], family: family) }
    let(:eligibility_determination) {EligibilityDetermination.new(csr_eligibility_kind: 'csr_87', determined_at: TimeKeeper.date_of_record)}
    let(:tax_household) do
      tax_household = TaxHousehold.new
      tax_household.tax_household_members.build(is_ia_eligible: true, applicant_id: 'member1')
      tax_household.tax_household_members.build(is_ia_eligible: true, applicant_id: 'member2')
      tax_household
    end

    before do
      FinancialAssistanceRegistry[:native_american_csr].feature.stub(:is_enabled).and_return(false)
      allow(tax_household).to receive(:eligibility_determinations).and_return([eligibility_determination])
    end

    it "should equal to the available csr_kind of tax household members" do
      tax_household.eligibility_determinations = [eligibility_determination]
      expect(tax_household.valid_csr_kind(hbx_enrollment)).to eq tax_household.tax_household_members.first.csr_eligibility_kind
    end
  end

  context 'is_all_non_aptc?' do
    let!(:family) {create(:family, :with_primary_family_member_and_dependent)}
    let(:household) {create(:household, family: family)}
    let!(:tax_household) {create(:tax_household, household: household)}
    let(:hbx_enrollment) {create(:hbx_enrollment, :with_enrollment_members, family: family, household: household)}

    context 'when all family_members are medicaid' do
      before do
        allow(tax_household).to receive(:is_all_non_aptc?).and_return false
      end
      it 'should return false' do
        result = tax_household.is_all_non_aptc?(hbx_enrollment)
        expect(result).to eq(false)
      end
    end

    context 'when all family_members are not medicaid' do
      it 'should return true' do
        result = tax_household.is_all_non_aptc?(hbx_enrollment)
        expect(result).to eq(true)
      end
    end
  end

  context '#eligible_csr_percent_as_integer' do
    let!(:family) { create(:family, :with_primary_family_member_and_dependent) }
    let!(:person) { family.primary_person }
    let(:household) {create(:household, family: family)}
    let!(:tax_household) {create(:tax_household, household: household)}
    let!(:tax_household_member) {tax_household.tax_household_members.create!(is_ia_eligible: true, csr_eligibility_kind: "csr_100")}
    let(:hbx_enrollment_member){ FactoryBot.build(:hbx_enrollment_member, is_subscriber: true, applicant_id: person.primary_family.family_members[0].id) }
    let(:hbx_enrollment) do
      FactoryBot.create(:hbx_enrollment, :with_product,
                        family: family,
                        household: household,
                        hbx_enrollment_members: [hbx_enrollment_member],
                        coverage_kind: "health")
    end

    before do
      tax_household.tax_household_members.first.update_attributes!(applicant_id: family.family_members[0].id)
    end

    context 'when all csr percent is csr_100 for tax household members' do
      it 'should return correct csr value' do
        result = tax_household.eligible_csr_percent_as_integer(hbx_enrollment.hbx_enrollment_members.map(&:applicant_id))
        expect(result).to eq(100)
      end
    end

    context 'when all csr percent is csr_94 for tax household members' do
      it 'should return correct csr value' do
        tax_household_member.update_attributes(csr_eligibility_kind: "csr_94")
        result = tax_household.eligible_csr_percent_as_integer(hbx_enrollment.hbx_enrollment_members.map(&:applicant_id))
        csr_kind = tax_household.valid_csr_kind(hbx_enrollment)

        expect(result).to eq(94)
        expect(csr_kind).to eq('csr_94')
      end
    end

    context 'when all default csr percent when thhm is not ia_eligible' do
      it 'should return correct csr value' do
        tax_household_member.update_attributes(is_ia_eligible: false)
        result = tax_household.eligible_csr_percent_as_integer(hbx_enrollment.hbx_enrollment_members.map(&:applicant_id))
        csr_kind = tax_household.valid_csr_kind(hbx_enrollment)

        expect(result).to eq(0)
        expect(csr_kind).to eq("csr_0")
      end
    end

    context 'when all csr percent is csr_limited for tax household members' do
      it 'should return correct csr value' do
        tax_household_member.update_attributes(csr_eligibility_kind: "csr_limited")
        result = tax_household.eligible_csr_percent_as_integer(hbx_enrollment.hbx_enrollment_members.map(&:applicant_id))
        csr_kind = tax_household.valid_csr_kind(hbx_enrollment)

        expect(result).to eq('limited')
        expect(csr_kind).to eq("csr_limited")
      end
    end

    context 'when all csr percent is csr_73 for tax household members' do
      it 'should return correct csr value' do
        tax_household_member.update_attributes(csr_eligibility_kind: "csr_73")
        result = tax_household.eligible_csr_percent_as_integer(hbx_enrollment.hbx_enrollment_members.map(&:applicant_id))
        csr_kind = tax_household.valid_csr_kind(hbx_enrollment)

        expect(result).to eq(73)
        expect(csr_kind).to eq("csr_73")
      end
    end
  end

  context 'total_aptc_available_amount_for_enrollment' do
    let!(:rating_area) do
      ::BenefitMarkets::Locations::RatingArea.rating_area_for(address, during: effective_on) || FactoryBot.create_default(:benefit_markets_locations_rating_area, active_year: effective_on.year)
    end
    let!(:service_area) do
      ::BenefitMarkets::Locations::ServiceArea.service_areas_for(address, during: effective_on).first || FactoryBot.create_default(:benefit_markets_locations_service_area, active_year: effective_on.year)
    end
    let(:address) { person.rating_address }
    let!(:hbx_profile) {FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period)}
    let!(:family) { create(:family, :with_primary_family_member_and_dependent) }
    let!(:person) { family.primary_person }
    let(:household) { family.active_household }
    let!(:tax_household) { create(:tax_household, household: household, effective_ending_on: nil) }
    let!(:tax_household_member1) {tax_household.tax_household_members.create!(is_ia_eligible: true, applicant_id: person.primary_family.family_members[0].id)}
    let!(:tax_household_member2) {tax_household.tax_household_members.create!(is_ia_eligible: true, applicant_id: person.primary_family.family_members[1].id)}
    let!(:tax_household_member3) {tax_household.tax_household_members.create!(is_ia_eligible: true, applicant_id: person.primary_family.family_members[2].id)}
    let!(:eligibility) { FactoryBot.create(:eligibility_determination, tax_household: tax_household, max_aptc: 210) }
    let(:hbx_enrollment) { create(:hbx_enrollment, :with_enrollment_members, family: family, household: household) }
    let(:member_ids) { family.active_family_members.collect(&:id) }
    let(:benefit_sponsorship) {double("benefit sponsorship", earliest_effective_date: TimeKeeper.date_of_record.beginning_of_year)}
    let(:current_hbx) {double("current hbx", benefit_sponsorship: benefit_sponsorship, under_open_enrollment?: true)}

    let(:application_period) { effective_on.beginning_of_year..effective_on.end_of_year }
    let!(:product) do
      prod =
        FactoryBot.create(
          :benefit_markets_products_health_products_health_product,
          :with_issuer_profile,
          benefit_market_kind: :aca_individual,
          kind: :health,
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

    let(:total_aptc_available_amount) { 210 }
    let(:monthly_available_aptc) { 1260.0 }
    let(:effective_on) { Date.new(TimeKeeper.date_of_record.year, 11, 1) }
    let!(:hbx_enrollment_aptc) do
      FactoryBot.create(
        :hbx_enrollment,
        :with_health_product,
        waiver_reason: nil,
        kind: 'individual',
        enrollment_kind: 'special_enrollment',
        coverage_kind: 'health',
        rating_area_id: rating_area.id,
        effective_on: effective_on,
        submitted_at: TimeKeeper.date_of_record - 6.months,
        household: family.active_household,
        family: family,
        product: product
      )
    end

    before :each do
      hbx_profile.benefit_sponsorship.benefit_coverage_periods.detect {|bcp| bcp.contains?(TimeKeeper.datetime_of_record)}.update_attributes!(slcsp_id: product.id)
    end

    context 'when all family members checked' do
      before do
        allow(tax_household).to receive(:unwanted_family_members).and_return []
      end

      context 'when all family_members are medicaid' do
        before do
          allow(tax_household).to receive(:is_all_non_aptc?).and_return false
        end

        it 'should return all members amount' do
          result = tax_household.total_aptc_available_amount_for_enrollment(hbx_enrollment, hbx_enrollment.effective_on)
          expect(result).to eq(total_aptc_available_amount)
        end
      end

      context 'when all family_members are not medicaid' do
        it 'should return 0' do
          result = tax_household.total_aptc_available_amount_for_enrollment(hbx_enrollment, hbx_enrollment.effective_on)
          expect(result).to eq(0)
        end
      end
    end

    context 'when family members unchecked' do
      let(:total_benchmark_amount) { 60 }
      before do
        allow(tax_household).to receive(:unwanted_family_members).and_return [family.active_family_members[0]]
        allow(tax_household).to receive(:total_benchmark_amount).and_return total_benchmark_amount
        allow(tax_household).to receive(:is_all_non_aptc?).and_return false
        allow(tax_household).to receive(:find_aptc_family_members).and_return true
      end

      it 'should deduct benchmark cost' do
        result = tax_household.total_aptc_available_amount_for_enrollment(hbx_enrollment, hbx_enrollment.effective_on)
        expect(result).not_to eq(total_aptc_available_amount)
        expect(result).to eq(total_aptc_available_amount - total_benchmark_amount)
      end
    end

    context 'calculate_monthly_aggregate feature enabled' do
      let!(:enr_members) do
        family.active_family_members.each do |fm|
          FactoryBot.create(:hbx_enrollment_member, applicant_id: fm.id, is_subscriber: fm.is_primary_applicant, hbx_enrollment: hbx_enrollment_aptc)
        end
      end

      before do
        hbx_enrollment_aptc.update_attributes!(effective_on: TimeKeeper.date_of_record.beginning_of_year, applied_aptc_amount: 150.00)
        allow(TimeKeeper).to receive(:date_of_record).and_return(Date.new(TimeKeeper.date_of_record.year, 8, 1))
        allow(EnrollRegistry[:calculate_monthly_aggregate].feature).to receive(:is_enabled).and_return(true)
        @result = tax_household.total_aptc_available_amount_for_enrollment(hbx_enrollment_aptc, TimeKeeper.date_of_record)
      end

      it 'should return monthly aggregate amount' do
        expect(@result).to eq(294)
      end

      context 'when thhms are different for two 2 thhs' do
        let!(:new_tax_household) { create(:tax_household, created_at: (tax_household.created_at + 1.day), effective_starting_on: (tax_household.effective_starting_on + 10.days), household: household, effective_ending_on: nil) }
        let!(:new_tax_household_member1) {new_tax_household.tax_household_members.create!(is_ia_eligible: true, applicant_id: person.primary_family.family_members[0].id)}
        let!(:new_tax_household_member2) {new_tax_household.tax_household_members.create!(is_ia_eligible: true, applicant_id: person.primary_family.family_members[1].id)}
        let!(:new_tax_household_member3) {new_tax_household.tax_household_members.create!(is_ia_eligible: false, applicant_id: person.primary_family.family_members[2].id)}
        let!(:new_eligibility) { FactoryBot.create(:eligibility_determination, tax_household: new_tax_household, max_aptc: 250) }

        before do
          tax_household.update_attributes(effective_ending_on: new_tax_household.effective_starting_on - 1.day)
          @result = new_tax_household.total_aptc_available_amount_for_enrollment(hbx_enrollment_aptc, TimeKeeper.date_of_record)
        end

        it 'should return max aptc' do
          expect(@result).to eq(250)
        end
      end
    end
  end

  context '#find_aptc_tax_household_members' do
    let!(:person) {FactoryBot.create(:person, :with_family)}
    let!(:family) {person.primary_family}
    let!(:family_member1) {FactoryBot.create(:family_member, family: person.primary_family)}
    let!(:family_member2) {FactoryBot.create(:family_member, family: person.primary_family)}
    let!(:tax_household) {FactoryBot.create(:tax_household, household: family.active_household, created_at: TimeKeeper.date_of_record - 5.months)}
    let!(:tax_household_member1) {tax_household.tax_household_members.create!(is_ia_eligible: true, applicant_id: person.primary_family.family_members[0].id)}
    let!(:tax_household_member2) {tax_household.tax_household_members.create!(is_ia_eligible: true, applicant_id: family_member1.id)}
    let!(:tax_household_member3) {tax_household.tax_household_members.create!(is_ia_eligible: false, is_medicaid_chip_eligible: true, applicant_id: family_member2.id)}

    it 'should return eligible tax household members' do
      expect(tax_household.find_aptc_tax_household_members([family_member1, family_member2])).to eq([tax_household_member2])
    end
  end

  describe "total_aptc_available_amount_for_enrollment", dbclean: :after_each do

    context 'for family_members with two aptc eligible and one medicaid' do
      let(:address) { person.rating_address }
      let!(:rating_area) do
        ::BenefitMarkets::Locations::RatingArea.rating_area_for(address, during: effective_on) || FactoryBot.create_default(:benefit_markets_locations_rating_area, active_year: effective_on.year)
      end
      let!(:service_area) do
        ::BenefitMarkets::Locations::ServiceArea.service_areas_for(address, during: effective_on).first || FactoryBot.create_default(:benefit_markets_locations_service_area, active_year: effective_on.year)
      end
      let(:application_period) { effective_on.beginning_of_year..effective_on.end_of_year }
      let!(:product) do
        prod =
          FactoryBot.create(
            :benefit_markets_products_health_products_health_product,
            :with_issuer_profile,
            benefit_market_kind: :aca_individual,
            kind: :health,
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
      let(:effective_on) { TimeKeeper.date_of_record.beginning_of_month }
      let!(:hbx_enrollment) do
        FactoryBot.create(
          :hbx_enrollment,
          :with_health_product,
          waiver_reason: nil,
          kind: 'individual',
          enrollment_kind: 'special_enrollment',
          coverage_kind: 'health',
          submitted_at: TimeKeeper.date_of_record - 6.months,
          rating_area_id: rating_area.id,
          effective_on: effective_on,
          household: family.active_household,
          family: family,
          product: product
        )
      end

      let!(:hbx_profile) {FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period)}
      let(:plan) {FactoryBot.create(:plan, :with_premium_tables, market: 'individual', metal_level: 'silver', csr_variant_id: '01', active_year: TimeKeeper.date_of_record.year, hios_id: '94506DC0390014-01')}

      let!(:person) {FactoryBot.create(:person, :with_family)}
      let!(:family) {person.primary_family}
      let!(:family_member1) {FactoryBot.create(:family_member, family: person.primary_family)}
      let!(:family_member2) {FactoryBot.create(:family_member, family: person.primary_family)}
      let(:member_ids) {family.active_family_members.collect(&:id)}
      let!(:hbx_enrollment_member1) {FactoryBot.create(:hbx_enrollment_member, applicant_id: family.family_members.first.id, eligibility_date: TimeKeeper.date_of_record, coverage_start_on: TimeKeeper.date_of_record, hbx_enrollment: hbx_enrollment)}
      let!(:hbx_enrollment_member2) {FactoryBot.create(:hbx_enrollment_member, applicant_id: family.family_members.second.id, eligibility_date: TimeKeeper.date_of_record, coverage_start_on: TimeKeeper.date_of_record, hbx_enrollment: hbx_enrollment)}
      let!(:hbx_enrollment_member3) {FactoryBot.create(:hbx_enrollment_member, applicant_id: family.family_members.last.id, eligibility_date: TimeKeeper.date_of_record, coverage_start_on: TimeKeeper.date_of_record, hbx_enrollment: hbx_enrollment)}
      let!(:tax_household) {FactoryBot.create(:tax_household, household: family.active_household, created_at: TimeKeeper.date_of_record - 5.months)}
      let!(:tax_household_member1) {tax_household.tax_household_members.create!(is_ia_eligible: true, applicant_id: person.primary_family.family_members[0].id)}
      let!(:tax_household_member2) {tax_household.tax_household_members.create!(is_ia_eligible: true, applicant_id: person.primary_family.family_members[1].id)}
      let!(:tax_household_member3) {tax_household.tax_household_members.create!(is_ia_eligible: false, is_medicaid_chip_eligible: true, applicant_id: person.primary_family.family_members[2].id)}
      let!(:eligibility_determination) {FactoryBot.create(:eligibility_determination, max_aptc: 500, tax_household: tax_household)}

      before do
        hbx_profile.benefit_sponsorship.benefit_coverage_periods.detect {|bcp| bcp.contains?(TimeKeeper.datetime_of_record)}.update_attributes!(slcsp_id: product.id)
        person.update_attributes!(dob: TimeKeeper.date_of_record - 38.years)
        person.primary_family.family_members[1].person.update_attributes!(dob: TimeKeeper.date_of_record - 28.years)
        person.primary_family.family_members[2].person.update_attributes!(dob: TimeKeeper.date_of_record - 18.years)
      end

      context 'having only one previous non aptc enrollment' do
        context 'when one family_member in plan shopping' do

          let(:shopping_hbx_enrollment_member) {FactoryBot.build(:hbx_enrollment_member, applicant_id: family.family_members.first.id)}
          let(:shopping_hbx_enrollment) do
            FactoryBot.build(
              :hbx_enrollment,
              family: family,
              aasm_state: 'shopping',
              effective_on: TimeKeeper.date_of_record.beginning_of_month,
              hbx_enrollment_members: [shopping_hbx_enrollment_member],
              household: family.active_household,
              rating_area_id: rating_area.id,
              product: product
            )
          end

          before do
            ::BenefitMarkets::Products::ProductRateCache.initialize_rate_cache!
          end

          it 'should return available APTC amount' do
            result = tax_household.total_aptc_available_amount_for_enrollment(shopping_hbx_enrollment, shopping_hbx_enrollment.effective_on)
            expect(result).to eq(301.14)
          end
        end

        context 'when two family_members in plan shopping' do

          let(:shopping_hbx_enrollment_member) {FactoryBot.build(:hbx_enrollment_member, eligibility_date: TimeKeeper.date_of_record + 1.month, applicant_id: family.family_members.first.id)}
          let(:shopping_hbx_enrollment_member1) {FactoryBot.build(:hbx_enrollment_member, eligibility_date: TimeKeeper.date_of_record + 1.month, applicant_id: family.family_members.second.id)}
          let(:shopping_hbx_enrollment) {FactoryBot.build(:hbx_enrollment, family: family, aasm_state: 'shopping', hbx_enrollment_members: [shopping_hbx_enrollment_member, shopping_hbx_enrollment_member1], household: family.active_household, product: product)}

          it 'should return available APTC amount' do
            result = tax_household.total_aptc_available_amount_for_enrollment(shopping_hbx_enrollment, shopping_hbx_enrollment.effective_on)
            expect(result).to eq(500.00)
          end
        end

        context 'when all family_members in plan shopping' do

          let(:shopping_hbx_enrollment_member) {FactoryBot.build(:hbx_enrollment_member, applicant_id: family.family_members.first.id)}
          let(:shopping_hbx_enrollment_member1) {FactoryBot.build(:hbx_enrollment_member, applicant_id: family.family_members.second.id)}
          let(:shopping_hbx_enrollment_member2) {FactoryBot.build(:hbx_enrollment_member, applicant_id: family.family_members.last.id)}
          let(:shopping_hbx_enrollment) do
            FactoryBot.build(:hbx_enrollment, aasm_state: 'shopping',family: family, hbx_enrollment_members: [shopping_hbx_enrollment_member, shopping_hbx_enrollment_member1, shopping_hbx_enrollment_member2], household: family.active_household, product: product)
          end

          it 'should return available APTC amount' do
            result = tax_household.total_aptc_available_amount_for_enrollment(shopping_hbx_enrollment, shopping_hbx_enrollment.effective_on)
            expect(result).to eq(500.00)
          end
        end

        context 'having only one previous aptc enrollment & one non aptc enrollment' do

          let!(:hbx_enrollment_member1) do
            FactoryBot.create(:hbx_enrollment_member,
                              applicant_id: family.family_members.first.id,
                              eligibility_date: TimeKeeper.date_of_record,
                              coverage_start_on: TimeKeeper.date_of_record,
                              hbx_enrollment: aptc_enrollment1,
                              applied_aptc_amount: 278.68)
          end

          let!(:hbx_enrollment_member2) do
            FactoryBot.create(:hbx_enrollment_member,
                              applicant_id: family.family_members.second.id,
                              eligibility_date: TimeKeeper.date_of_record,
                              coverage_start_on: TimeKeeper.date_of_record,
                              hbx_enrollment: aptc_enrollment1,
                              applied_aptc_amount: 221.32)
          end
          let!(:hbx_enrollment_member3) do
            FactoryBot.create(:hbx_enrollment_member, applicant_id: family.family_members.last.id, eligibility_date: TimeKeeper.date_of_record, coverage_start_on: TimeKeeper.date_of_record, hbx_enrollment: aptc_enrollment1)
          end
          let!(:aptc_enrollment1) do
            FactoryBot.create(:hbx_enrollment,
                              family: family,
                              submitted_at: TimeKeeper.date_of_record + 1.month,
                              household: family.active_household,
                              is_active: true,
                              aasm_state: 'coverage_selected',
                              changing: false,
                              effective_on: (TimeKeeper.date_of_record.beginning_of_month + 10.days),
                              kind: 'individual',
                              applied_aptc_amount: 500.00)
          end
          let(:shopping_hbx_enrollment_member1) {FactoryBot.build(:hbx_enrollment_member, applicant_id: family.family_members.first.id, eligibility_date: TimeKeeper.date_of_record + 1.month)}
          let(:shopping_hbx_enrollment_member2) {FactoryBot.build(:hbx_enrollment_member, applicant_id: family.family_members.second.id, eligibility_date: TimeKeeper.date_of_record + 1.month)}
          let(:shopping_hbx_enrollment_member3) do
            FactoryBot.build(:hbx_enrollment_member,
                             applicant_id: family.family_members.last.id,
                             eligibility_date: TimeKeeper.date_of_record + 1.month)
          end

          let(:shopping_hbx_enrollment1) do
            FactoryBot.build(:hbx_enrollment,
                             family: family,
                             coverage_kind: 'health',
                             aasm_state: 'shopping',
                             household: family.active_household,
                             hbx_enrollment_members: [shopping_hbx_enrollment_member1,
                                                      shopping_hbx_enrollment_member2,
                                                      shopping_hbx_enrollment_member3])
          end

          before do
            eligibility_determination.update_attributes(max_aptc: 1000.00)
            aptc_enrollment1.household.reload
            hbx_enrollment.household.reload
            family.reload
          end

          it 'should have two enrollments in enrolled state for a family' do
            expect(family.active_household.hbx_enrollments.count).to eq(2)
          end

          it 'Should return max APTC amount' do
            result = tax_household.total_aptc_available_amount_for_enrollment(shopping_hbx_enrollment1, shopping_hbx_enrollment1.effective_on)
            expect(result.round(2)).to eq(1000.00)
          end

          context 'When enrollments has different subscribers' do
            before do
              aptc_enrollment1.hbx_enrollment_members.first.update_attributes(is_subscriber: false)
              aptc_enrollment1.hbx_enrollment_members.second.update_attributes(is_subscriber: false)
            end

            it 'Should return remaining aptc' do
              result = tax_household.total_aptc_available_amount_for_enrollment(shopping_hbx_enrollment1, shopping_hbx_enrollment1.effective_on)
              expect(result.round(2)).to eq(500.00)
            end

            it 'Should return remaining aptc with excluding enrollment.' do
              result = tax_household.total_aptc_available_amount_for_enrollment(shopping_hbx_enrollment1, shopping_hbx_enrollment1.effective_on, aptc_enrollment1.id)
              expect(result.round(2)).to eq(1000.00)
            end
          end
        end

        context 'having two previous aptc enrollment with one enrolled member each and third member in shopping' do
          let!(:hbx_enrollment_member1) do
            FactoryBot.create(:hbx_enrollment_member,
                              applicant_id: family.family_members.first.id,
                              eligibility_date: TimeKeeper.date_of_record,
                              coverage_start_on: TimeKeeper.date_of_record,
                              hbx_enrollment: aptc_enrollment1,
                              applied_aptc_amount: 32.21)
          end

          let!(:aptc_enrollment1) do
            FactoryBot.create(:hbx_enrollment,
                              family: family,
                              waiver_reason: nil,
                              kind: 'individual',
                              enrollment_kind: 'special_enrollment',
                              coverage_kind: 'health',
                              rating_area_id: rating_area.id,
                              submitted_at: TimeKeeper.date_of_record - 2.months,
                              effective_on: TimeKeeper.date_of_record.beginning_of_month,
                              aasm_state: 'coverage_selected',
                              household: family.active_household,
                              applied_aptc_amount: 32.21)
          end

          let!(:hbx_enrollment_member2) do
            FactoryBot.create(:hbx_enrollment_member,
                              applicant_id: family.family_members.second.id,
                              eligibility_date: TimeKeeper.date_of_record,
                              coverage_start_on: TimeKeeper.date_of_record,
                              hbx_enrollment: aptc_enrollment2,
                              applied_aptc_amount: 278.68)
          end

          let!(:aptc_enrollment2) do
            FactoryBot.create(:hbx_enrollment,
                              family: family,
                              waiver_reason: nil,
                              submitted_at: TimeKeeper.date_of_record - 1.month,
                              effective_on: TimeKeeper.date_of_record.beginning_of_month,
                              household: family.active_household,
                              enrollment_kind: 'special_enrollment',
                              rating_area_id: rating_area.id,
                              is_active: true,
                              aasm_state: 'coverage_selected',
                              changing: false,
                              kind: 'individual',
                              applied_aptc_amount: 278.68)
          end

          let(:shopping_hbx_enrollment_member1) do
            FactoryBot.build(:hbx_enrollment_member,
                             applicant_id: family.family_members.last.id,
                             eligibility_date: TimeKeeper.date_of_record + 1.month)
          end
          let(:shopping_hbx_enrollment1) do
            FactoryBot.build(:hbx_enrollment,
                             family: family, coverage_kind: 'health',
                             effective_on: TimeKeeper.date_of_record.beginning_of_month,
                             household: family.active_household, aasm_state: 'shopping',
                             hbx_enrollment_members: [shopping_hbx_enrollment_member1])
          end

          before do
            tax_household_member3.update_attributes(is_ia_eligible: true)
            eligibility_determination.update_attributes(max_aptc: 500.00)
            aptc_enrollment2.household.reload
            aptc_enrollment1.household.reload
            hbx_enrollment.household.reload
            family.reload
          end

          it 'should have two enrollments in enrolled state for a family' do
            expect(family.active_household.hbx_enrollments.count).to eq(3)
          end

          it 'should return available APTC amount' do
            result = tax_household.total_aptc_available_amount_for_enrollment(shopping_hbx_enrollment1, shopping_hbx_enrollment1.effective_on)
            expect(result.round(2)).to eq(189.11)
          end
        end

        context 'when all checked family_members in plan shopping ' do
          let(:shopping_hbx_enrollment_member){ FactoryBot.build(:hbx_enrollment_member, applicant_id: family.family_members.first.id) }
          let(:shopping_hbx_enrollment_member1){ FactoryBot.build(:hbx_enrollment_member, applicant_id: family.family_members.second.id) }
          let(:shopping_hbx_enrollment_member2){ FactoryBot.build(:hbx_enrollment_member, applicant_id: family.family_members.last.id) }
          let(:shopping_hbx_enrollment) do
            FactoryBot.build(:hbx_enrollment,
                             family: family,
                             aasm_state: "shopping",
                             hbx_enrollment_members: [shopping_hbx_enrollment_member, shopping_hbx_enrollment_member1, shopping_hbx_enrollment_member2],
                             household: family.active_household)
          end

          it 'should return all checked members' do
            expect(tax_household.find_enrolling_fms(shopping_hbx_enrollment).count).to eq(3)
          end
        end

        context 'having one member is enrolled and one member is unchecked and third member in shopping' do
          let!(:hbx_enrollment_member1) do
            FactoryBot.create(:hbx_enrollment_member,
                              applicant_id: family.family_members.first.id,
                              eligibility_date: TimeKeeper.date_of_record,
                              coverage_start_on: TimeKeeper.date_of_record,
                              hbx_enrollment: aptc_enrollment1,
                              applied_aptc_amount: 32.21)
          end

          let!(:aptc_enrollment1) do
            FactoryBot.create(:hbx_enrollment,
                              family: family,
                              waiver_reason: nil,
                              kind: 'individual',
                              enrollment_kind: 'special_enrollment',
                              coverage_kind: 'health',
                              submitted_at: TimeKeeper.date_of_record - 2.months,
                              aasm_state: 'coverage_selected',
                              household: family.active_household,
                              applied_aptc_amount: 32.21)
          end

          let!(:hbx_enrollment_member2) do
            FactoryBot.create(:hbx_enrollment_member,
                              applicant_id: family.family_members.first.id,
                              eligibility_date: TimeKeeper.date_of_record,
                              coverage_start_on: TimeKeeper.date_of_record,
                              hbx_enrollment: hbx_enrollment)
          end
          let(:shopping_hbx_enrollment_member3) {FactoryBot.build(:hbx_enrollment_member, applicant_id: family.family_members.last.id)}
          let(:shopping_hbx_enrollment) {FactoryBot.build(:hbx_enrollment, family: family, aasm_state: 'shopping', hbx_enrollment_members: [shopping_hbx_enrollment_member3], household: family.active_household)}

          it 'should return only unwanted_family_members' do
            expect(tax_household.unwanted_family_members(shopping_hbx_enrollment).count).to eq(1)
          end
        end

        context 'having two previous aptc enrollment and third member in shopping' do
          let!(:hbx_enrollment_member1) do
            FactoryBot.create(:hbx_enrollment_member,
                              applicant_id: family.family_members.first.id,
                              eligibility_date: TimeKeeper.date_of_record,
                              coverage_start_on: TimeKeeper.date_of_record,
                              hbx_enrollment: aptc_enrollment1,
                              applied_aptc_amount: 32.21)
          end

          let!(:aptc_enrollment1) do
            FactoryBot.create(:hbx_enrollment,
                              family: family,
                              waiver_reason: nil,
                              kind: 'individual',
                              enrollment_kind: 'special_enrollment',
                              coverage_kind: 'health',
                              submitted_at: TimeKeeper.date_of_record - 2.months,
                              aasm_state: 'coverage_selected',
                              household: family.active_household,
                              applied_aptc_amount: 32.21)
          end

          let!(:hbx_enrollment_member2) do
            FactoryBot.create(:hbx_enrollment_member,
                              applicant_id: family.family_members.second.id,
                              eligibility_date: TimeKeeper.date_of_record,
                              coverage_start_on: TimeKeeper.date_of_record,
                              hbx_enrollment: aptc_enrollment2,
                              applied_aptc_amount: 278.68)
          end

          let!(:aptc_enrollment2) do
            FactoryBot.create(:hbx_enrollment,
                              family: family,
                              waiver_reason: nil,
                              submitted_at: TimeKeeper.date_of_record - 1.month,
                              household: family.active_household,
                              enrollment_kind: 'special_enrollment',
                              is_active: true,
                              aasm_state: 'coverage_selected',
                              changing: false,
                              kind: 'individual',
                              applied_aptc_amount: 278.68)
          end

          let(:shopping_hbx_enrollment_member1) {FactoryBot.build(:hbx_enrollment_member, applicant_id: family.family_members.last.id, eligibility_date: TimeKeeper.date_of_record + 1.month)}
          let(:shopping_hbx_enrollment1) {FactoryBot.build(:hbx_enrollment, family: family, coverage_kind: 'health', aasm_state: 'shopping', household: family.active_household, hbx_enrollment_members: [shopping_hbx_enrollment_member1])}

          it 'should return enrolled family_members' do
            expect(tax_household.aptc_family_members_by_tax_household.count).to eq(2)
          end
        end
        context 'first two family_members are in is_ia_eligible and third is medicaid ' do
          let(:shopping_hbx_enrollment_member2) {FactoryBot.build(:hbx_enrollment_member, applicant_id: family.family_members.last.id)}
          let(:shopping_hbx_enrollment) {FactoryBot.build(:hbx_enrollment, family: family, aasm_state: 'shopping', hbx_enrollment_members: [shopping_hbx_enrollment_member2], household: family.active_household)}

          it 'should return medicaid family_members only' do
            expect(tax_household.find_non_aptc_fms(shopping_hbx_enrollment.hbx_enrollment_members.map(&:family_member)).count).to eq(1)
          end
        end
      end
    end
  end
end
