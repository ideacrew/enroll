# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HbxEnrollment, type: :model do
  include FloatHelper

  before :all do
    DatabaseCleaner.clean
  end

  let(:start_of_month) { TimeKeeper.date_of_record.beginning_of_month }
  let(:person) { create(:person, :with_consumer_role, :with_active_consumer_role, first_name: 'test1') }
  let(:family) { create(:family, :with_primary_family_member, person: person) }
  let(:aasm_state) { 'coverage_selected' }
  let(:hbx_enrollment) do
    create(:hbx_enrollment, :individual_aptc, :with_silver_health_product, aasm_state: aasm_state,
                                                                           applied_aptc_amount: applied_aptc_amount,
                                                                           elected_aptc_pct: elected_aptc_pct,
                                                                           family: family,
                                                                           consumer_role_id: person.consumer_role.id,
                                                                           ehb_premium: enrollment_ehb_premium)
  end

  let(:hbx_enrollment_member) do
    create(:hbx_enrollment_member, hbx_enrollment: hbx_enrollment,
                                   applicant_id: family.primary_applicant.id,
                                   coverage_start_on: start_of_month,
                                   eligibility_date: start_of_month)
  end

  let!(:tax_household_enrollment) do
    thh_enr = TaxHouseholdEnrollment.create(
      enrollment_id: hbx_enrollment.id, tax_household_id: tax_household_group.tax_households.first.id,
      household_benchmark_ehb_premium: 500.00, available_max_aptc: available_max_aptc
    )

    thh_enr.tax_household_members_enrollment_members.create(
      family_member_id: hbx_enrollment_member.applicant_id, hbx_enrollment_member_id: hbx_enrollment_member.id,
      tax_household_member_id: tax_household_group.tax_households.first.tax_household_members.first.id,
      age_on_effective_date: 20, relationship_with_primary: 'self', date_of_birth: start_of_month - 20.years
    )
    thh_enr
  end

  let(:person2) do
    per = create(:person, :with_consumer_role, :with_active_consumer_role, first_name: 'test2')
    person.ensure_relationship_with(per, 'spouse')
    per
  end

  let(:family_member) { create(:family_member, person: person2, family: family) }

  let(:hbx_enrollment_member2) do
    create(:hbx_enrollment_member, is_subscriber: false,
                                   hbx_enrollment: hbx_enrollment,
                                   applicant_id: family_member.id,
                                   coverage_start_on: start_of_month,
                                   eligibility_date: start_of_month)
  end

  let(:tax_household_group) do
    thhg = family.tax_household_groups.create!(
      assistance_year: start_of_month.year, source: 'Admin', start_on: start_of_month.year,
      tax_households: [
        FactoryBot.build(:tax_household, household: family.active_household),
        FactoryBot.build(:tax_household, household: family.active_household)
      ]
    )

    thhg.tax_households.first.tax_household_members.create!(
      applicant_id: family.primary_applicant.id, is_ia_eligible: true
    )

    thhg.tax_households[1].tax_household_members.create!(
      applicant_id: family_member.id, is_ia_eligible: true
    )
    thhg
  end

  let!(:tax_household_enrollment2) do
    thh_enr = TaxHouseholdEnrollment.create(
      enrollment_id: hbx_enrollment.id, tax_household_id: tax_household_group.tax_households[1].id,
      household_benchmark_ehb_premium: 500.00, available_max_aptc: available_max_aptc2
    )

    thh_enr.tax_household_members_enrollment_members.create(
      family_member_id: hbx_enrollment_member2.applicant_id, hbx_enrollment_member_id: hbx_enrollment_member2.id,
      tax_household_member_id: tax_household_group.tax_households[1].tax_household_members.first.id,
      age_on_effective_date: 20, relationship_with_primary: 'self', date_of_birth: start_of_month - 20.years
    )
    thh_enr
  end

  before do
    ::BenefitMarkets::Products::ProductRateCache.initialize_rate_cache!
    EnrollRegistry[:temporary_configuration_enable_multi_tax_household_feature].feature.stub(:is_enabled).and_return(true)

    allow(
      hbx_enrollment.ivl_decorated_hbx_enrollment
    ).to receive(:member_ehb_premium).with(hbx_enrollment_member).and_return(member1_ehb_premium)

    allow(
      hbx_enrollment.ivl_decorated_hbx_enrollment
    ).to receive(:member_ehb_premium).with(hbx_enrollment_member2).and_return(member2_ehb_premium)
  end

  let(:member1_ehb_premium) { 350.00 }
  let(:member2_ehb_premium) { 375.00 }
  let(:available_max_aptc) { 250.00 }
  let(:available_max_aptc2) { 275.00 }
  let(:applied_aptc_amount) { available_max_aptc + available_max_aptc2 }
  let(:enrollment_ehb_premium) { member1_ehb_premium + member2_ehb_premium }
  let(:elected_aptc_pct) { 1.0 }

  describe '#renew_enrollment' do
    let(:aasm_state) { 'shopping' }

    it 'sets applied_aptc and group_ehb_premium' do
      expect(tax_household_enrollment.applied_aptc).to be_nil
      expect(tax_household_enrollment.group_ehb_premium).to be_nil
      expect(tax_household_enrollment2.applied_aptc).to be_nil
      expect(tax_household_enrollment2.group_ehb_premium).to be_nil
      hbx_enrollment.renew_enrollment!
      expect(tax_household_enrollment.reload.applied_aptc.to_f).to eq(available_max_aptc)
      expect(tax_household_enrollment.reload.group_ehb_premium.to_f).to eq(member1_ehb_premium)
      expect(tax_household_enrollment2.reload.applied_aptc.to_f).to eq(available_max_aptc2)
      expect(tax_household_enrollment2.reload.group_ehb_premium.to_f).to eq(member2_ehb_premium)
    end
  end

  describe '#select_coverage' do
    let(:aasm_state) { 'shopping' }

    it 'sets applied_aptc and group_ehb_premium' do
      expect(tax_household_enrollment.applied_aptc).to be_nil
      expect(tax_household_enrollment.group_ehb_premium).to be_nil
      expect(tax_household_enrollment2.applied_aptc).to be_nil
      expect(tax_household_enrollment2.group_ehb_premium).to be_nil
      hbx_enrollment.select_coverage!
      expect(tax_household_enrollment.reload.applied_aptc.to_f).to eq(available_max_aptc)
      expect(tax_household_enrollment.reload.group_ehb_premium.to_f).to eq(member1_ehb_premium)
      expect(tax_household_enrollment2.reload.applied_aptc.to_f).to eq(available_max_aptc2)
      expect(tax_household_enrollment2.reload.group_ehb_premium.to_f).to eq(member2_ehb_premium)
    end
  end

  describe '#update_tax_household_enrollment' do
    subject { hbx_enrollment.update_tax_household_enrollment }

    context 'with one aptc tax household enrollment' do
      let(:applied_aptc_amount) { 100.00 }

      before do
        tax_household_group.tax_households.first.tax_household_members.first.update_attributes!(
          is_ia_eligible: false, is_uqhp_eligible: true
        )
      end

      it 'sets applied_aptc same as applied_aptc_amount of the enrollment' do
        subject
        expect(tax_household_enrollment2.reload.applied_aptc.to_f).to eq(applied_aptc_amount)
        expect(tax_household_enrollment2.reload.group_ehb_premium.to_f).to eq(member2_ehb_premium)
      end
    end

    context 'with more than one aptc tax household enrollment' do

      context 'eligible applied aptcs are less than or equal to both group_ehb_premium and available_max_aptc' do
        it 'sets applied_aptc same as available_max_aptc' do
          subject
          expect(tax_household_enrollment.reload.applied_aptc.to_f).to eq(available_max_aptc)
          expect(tax_household_enrollment.reload.group_ehb_premium.to_f).to eq(member1_ehb_premium)
          expect(tax_household_enrollment2.reload.applied_aptc.to_f).to eq(available_max_aptc2)
          expect(tax_household_enrollment2.reload.group_ehb_premium.to_f).to eq(member2_ehb_premium)
        end
      end

      context 'member ehb premiums less than available max aptc' do
        let(:member1_ehb_premium) { 100.00 }
        let(:member2_ehb_premium) { 200.00 }
        let(:available_max_aptc) { 400.00 }
        let(:available_max_aptc2) { 500.00 }
        let(:applied_aptc_amount) { member1_ehb_premium + member2_ehb_premium }

        it 'sets applied_aptc' do
          subject
          expect(tax_household_enrollment.reload.applied_aptc.to_f).to eq(member1_ehb_premium)
          expect(tax_household_enrollment.reload.group_ehb_premium.to_f).to eq(member1_ehb_premium)
          expect(tax_household_enrollment2.reload.applied_aptc.to_f).to eq(member2_ehb_premium)
          expect(tax_household_enrollment2.reload.group_ehb_premium.to_f).to eq(member2_ehb_premium)
        end
      end

      context 'applied aptc amount is less than both ehb_premiums and available_max_aptcs' do
        let(:member1_ehb_premium) { 100.00 }
        let(:member2_ehb_premium) { 100.00 }
        let(:available_max_aptc) { 400.00 }
        let(:available_max_aptc2) { 500.00 }
        let(:applied_aptc_amount) { 200.00 }

        it 'applied_aptc_amount is split b/w aptc tax household enrollments' do
          subject
          expect(tax_household_enrollment.reload.group_ehb_premium.to_f).to eq(member1_ehb_premium)
          expect(tax_household_enrollment2.reload.group_ehb_premium.to_f).to eq(member2_ehb_premium)
          expect(
            tax_household_enrollment.applied_aptc + tax_household_enrollment2.applied_aptc
          ).to eq(applied_aptc_amount.to_money)
        end
      end

      context "one of the applied_aptcs_by_ratio's are greater than the group_ehb_premium" do
        let(:member1_ehb_premium) { 1054.31 }
        let(:member2_ehb_premium) { 302.19 }
        let(:available_max_aptc) { 1126.00 }
        let(:available_max_aptc2) { 343.00 }
        let(:applied_aptc_amount) { 1356.50 }

        it 'returns applied_aptc for aptc tax household enrollments which are below group_ehb_premium and available_max_aptc' do
          subject
          expect(
            tax_household_enrollment.reload.applied_aptc.to_f <= tax_household_enrollment.group_ehb_premium.to_f &&
              tax_household_enrollment.applied_aptc.to_f <= tax_household_enrollment.available_max_aptc.to_f
          ).to be_truthy
          expect(
            tax_household_enrollment2.reload.applied_aptc.to_f <= tax_household_enrollment2.group_ehb_premium.to_f &&
              tax_household_enrollment2.applied_aptc.to_f <= tax_household_enrollment2.available_max_aptc.to_f
          ).to be_truthy
          expect(
            tax_household_enrollment.applied_aptc + tax_household_enrollment2.applied_aptc
          ).to eq(applied_aptc_amount.to_money)
        end
      end

      context "applied_aptc_amount is less than both aptc tax household enrollment's group_ehb_premium, available_max_aptc" do
        let(:member1_ehb_premium) { 1054.31 }
        let(:member2_ehb_premium) { 302.19 }
        let(:available_max_aptc) { 1126.00 }
        let(:available_max_aptc2) { 343.00 }
        let(:applied_aptc_amount) { 100.00 }

        it 'returns applied_aptc for aptc tax household enrollments which are below group_ehb_premium and available_max_aptc' do
          subject
          expect(
            tax_household_enrollment.reload.applied_aptc.to_f <= tax_household_enrollment.group_ehb_premium.to_f &&
              tax_household_enrollment.applied_aptc.to_f <= tax_household_enrollment.available_max_aptc.to_f
          ).to be_truthy
          expect(
            tax_household_enrollment2.reload.applied_aptc.to_f <= tax_household_enrollment2.group_ehb_premium.to_f &&
              tax_household_enrollment2.applied_aptc.to_f <= tax_household_enrollment2.available_max_aptc.to_f
          ).to be_truthy
          expect(
            tax_household_enrollment.applied_aptc + tax_household_enrollment2.applied_aptc
          ).to eq(applied_aptc_amount.to_money)
        end
      end

      context "available_max_aptc of one aptc tax household is not positive" do
        let(:member1_ehb_premium) { 500.00 }
        let(:member2_ehb_premium) { 300.00 }
        let(:available_max_aptc) { -100.00 }
        let(:available_max_aptc2) { 400.00 }
        let(:applied_aptc_amount) { 350.00 }

        it 'returns applied_aptc of second tax household same as applied_aptc_amount' do
          subject
          expect(tax_household_enrollment2.reload.applied_aptc).to eq(applied_aptc_amount.to_money)
        end
      end
    end
  end

  describe ".reset_member_coverage_start_dates" do
    context "for one member coverage_start_on update" do
      let!(:effective_on) {hbx_enrollment.effective_on}
      let!(:beginning_of_year) {effective_on.beginning_of_year}
      let!(:enrollment_update) {hbx_enrollment.update_attributes(effective_on: beginning_of_year + 3.months)}
      let!(:member1_update) {hbx_enrollment.hbx_enrollment_members[0].update_attributes(coverage_start_on: beginning_of_year + 3.months)}
      let!(:member2_update) {hbx_enrollment.hbx_enrollment_members[1].update_attributes(coverage_start_on: beginning_of_year)}

      it 'should match with enrollment effective on' do
        enrollment_effective_on = hbx_enrollment.effective_on
        expect(hbx_enrollment.hbx_enrollment_members.pluck(:coverage_start_on)).to eq([enrollment_effective_on, beginning_of_year])
        hbx_enrollment.reset_member_coverage_start_dates
        expect(hbx_enrollment.hbx_enrollment_members.pluck(:coverage_start_on)).to eq([enrollment_effective_on, enrollment_effective_on])
      end
    end

    context "for all members coverage_start_on update" do
      let!(:effective_on) {hbx_enrollment.effective_on}
      let!(:beginning_of_year) {effective_on.beginning_of_year}
      let!(:enrollment_update) {hbx_enrollment.update_attributes(effective_on: beginning_of_year + 3.months)}
      let!(:member1_update) {hbx_enrollment.hbx_enrollment_members[0].update_attributes(coverage_start_on: beginning_of_year)}
      let!(:member2_update) {hbx_enrollment.hbx_enrollment_members[1].update_attributes(coverage_start_on: beginning_of_year)}

      it 'should match with enrollment effective on' do
        enrollment_effective_on = hbx_enrollment.effective_on
        expect(hbx_enrollment.hbx_enrollment_members.pluck(:coverage_start_on)).to eq([beginning_of_year, beginning_of_year])
        hbx_enrollment.reset_member_coverage_start_dates
        expect(hbx_enrollment.hbx_enrollment_members.pluck(:coverage_start_on)).to eq([enrollment_effective_on, enrollment_effective_on])
      end
    end

    context "when coverage_start_on matches with effective_on" do
      let!(:effective_on) {hbx_enrollment.effective_on}
      let!(:beginning_of_year) {effective_on.beginning_of_year}
      let!(:enrollment_update) {hbx_enrollment.update_attributes(effective_on: beginning_of_year + 3.months)}
      let!(:member1_update) {hbx_enrollment.hbx_enrollment_members[0].update_attributes(coverage_start_on: beginning_of_year + 3.months)}
      let!(:member2_update) {hbx_enrollment.hbx_enrollment_members[1].update_attributes(coverage_start_on: beginning_of_year + 3.months)}

      it 'should not update coverage_start_on' do
        enrollment_effective_on = hbx_enrollment.effective_on
        expect(hbx_enrollment.hbx_enrollment_members.pluck(:coverage_start_on)).to eq([enrollment_effective_on, enrollment_effective_on])
        hbx_enrollment.reset_member_coverage_start_dates
        expect(hbx_enrollment.hbx_enrollment_members.pluck(:coverage_start_on)).to eq([enrollment_effective_on, enrollment_effective_on])
      end
    end
  end
end
