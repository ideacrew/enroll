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
  let(:predecessor_enrollment_id) { nil }
  let(:purchase_event_published_at) { nil }
  let(:hbx_enrollment) do
    create(:hbx_enrollment, :individual_aptc, :with_silver_health_product, aasm_state: aasm_state,
                                                                           applied_aptc_amount: applied_aptc_amount,
                                                                           elected_aptc_pct: elected_aptc_pct,
                                                                           family: family,
                                                                           purchase_event_published_at: purchase_event_published_at,
                                                                           predecessor_enrollment_id: predecessor_enrollment_id,
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
    allow(EnrollRegistry[:temporary_configuration_enable_multi_tax_household_feature].feature).to receive(:is_enabled).and_return(true)

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

  describe '#cancel_coverage_for_superseded_term' do
    context "when:
      - enrollment is of kind 'individual'
      - enrollment is in 'coverage_terminated' state
      " do

      let(:aasm_state) { 'coverage_terminated' }

      it 'transitions enrollment to canceled' do
        expect(hbx_enrollment.may_cancel_coverage_for_superseded_term?).to be_truthy
        hbx_enrollment.cancel_coverage_for_superseded_term!
        expect(hbx_enrollment.reload.coverage_canceled?).to be_truthy
      end
    end

    context "when:
      - enrollment is of kind 'individual'
      - enrollment is not in 'coverage_terminated' state
      " do

      it 'returns false for transition check' do
        expect(hbx_enrollment.may_cancel_coverage_for_superseded_term?).to be_falsey
        expect do
          hbx_enrollment.cancel_coverage_for_superseded_term!
        end.to raise_error(AASM::InvalidTransition)
      end
    end

    context "when:
      - enrollment is not of kind 'individual'
      - enrollment is in 'coverage_terminated' state
      " do

      let(:aasm_state) { 'coverage_terminated' }

      it 'returns false for transition check' do
        allow(hbx_enrollment).to receive(:is_ivl_by_kind?).and_return(false)
        expect(hbx_enrollment.may_cancel_coverage_for_superseded_term?).to be_falsey
        expect do
          hbx_enrollment.cancel_coverage_for_superseded_term!
        end.to raise_error(AASM::InvalidTransition)
      end
    end
  end

  describe '#enrollment_superseded_and_eligible_for_cancellation?' do
    let(:person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
    let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
    let(:new_effective_on) { TimeKeeper.date_of_record }
    let(:aasm_state) { 'coverage_terminated' }
    let(:kind) { 'individual' }

    let(:prev_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        :with_silver_health_product,
                        :with_enrollment_members,
                        kind: kind,
                        enrollment_members: family.family_members,
                        aasm_state: aasm_state,
                        household: family.active_household,
                        effective_on: TimeKeeper.date_of_record,
                        family: family)
    end

    let(:feature_enabled) { true }

    before do
      allow(
        EnrollRegistry[:cancel_superseded_terminated_enrollments].feature
      ).to receive(:is_enabled).and_return(feature_enabled)
    end

    context "when:
      - RR configuration feature :cancel_superseded_terminated_enrollments is enabled
      - enrollment is of kind individual market
      - enrollment is terminated
      - new effective exists
      - new effective on's year is same as enrollment's effective_on's year
      " do

      it 'returns true' do
        expect(
          prev_enrollment.enrollment_superseded_and_eligible_for_cancellation?(new_effective_on)
        ).to be_truthy
      end
    end

    context "when:
      - RR configuration feature :cancel_superseded_terminated_enrollments is disabled
      - enrollment is of kind individual market
      - enrollment is terminated
      - new effective exists
      - new effective on's year is same as enrollment's effective_on's year
      " do

      let(:feature_enabled) { false }

      it 'returns false' do
        expect(
          prev_enrollment.enrollment_superseded_and_eligible_for_cancellation?(new_effective_on)
        ).to be_falsey
      end
    end

    context "when:
      - RR configuration feature :cancel_superseded_terminated_enrollments is enabled
      - enrollment is not of kind individual market
      - enrollment is terminated
      - new effective exists
      - new effective on's year is same as enrollment's effective_on's year
      " do

      let(:kind) { 'employer_sponsored' }

      it 'returns false' do
        expect(
          prev_enrollment.enrollment_superseded_and_eligible_for_cancellation?(new_effective_on)
        ).to be_falsey
      end
    end

    context "when:
      - RR configuration feature :cancel_superseded_terminated_enrollments is enabled
      - enrollment is of kind individual market
      - enrollment is not terminated
      - new effective exists
      - new effective on's year is same as enrollment's effective_on's year
      " do

      let(:aasm_state) { 'coverage_selected' }

      it 'returns false' do
        expect(
          prev_enrollment.enrollment_superseded_and_eligible_for_cancellation?(new_effective_on)
        ).to be_falsey
      end
    end

    context "when:
      - RR configuration feature :cancel_superseded_terminated_enrollments is enabled
      - enrollment is of kind individual market
      - enrollment is terminated
      - new effective does not exists
      " do

      let(:new_effective_on) { nil }

      it 'returns false' do
        expect(
          prev_enrollment.enrollment_superseded_and_eligible_for_cancellation?(new_effective_on)
        ).to be_falsey
      end
    end

    context "when:
      - RR configuration feature :cancel_superseded_terminated_enrollments is enabled
      - enrollment is of kind individual market
      - enrollment is not terminated
      - new effective exists
      - new effective on's year is not same as enrollment's effective_on's year
      " do

      let(:new_effective_on) { TimeKeeper.date_of_record.next_year }

      it 'returns false' do
        expect(
          prev_enrollment.enrollment_superseded_and_eligible_for_cancellation?(new_effective_on)
        ).to be_falsey
      end
    end
  end

  describe '#ineligible_for_termination?' do
    let(:person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
    let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
    let(:system_year) { TimeKeeper.date_of_record.year }
    let(:new_effective_on) { Date.new(system_year, 2) }
    let(:terminated_on) { Date.new(system_year, 2) - 1.day }
    let(:aasm_state) { 'coverage_terminated' }
    let(:kind) { 'individual' }

    let(:prev_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        :with_silver_health_product,
                        :with_enrollment_members,
                        kind: kind,
                        enrollment_members: family.family_members,
                        aasm_state: aasm_state,
                        terminated_on: terminated_on,
                        household: family.active_household,
                        effective_on: Date.new(system_year),
                        family: family)
    end

    context "when:
      - enrollment is of kind individual market
      - enrollment is terminated
      - enrollment has terminated_on
      - new effective exists
      - new effective on is one day after the enrollment's terminated_on
      " do

      it 'returns true' do
        expect(prev_enrollment.ineligible_for_termination?(new_effective_on)).to be_truthy
      end
    end

    context "when:
      - enrollment is not of kind individual market
      - enrollment is terminated
      - enrollment has terminated_on
      - new effective exists
      - new effective on is one day after the enrollment's terminated_on
      " do

      let(:kind) { 'employer_sponsored' }

      it 'returns false' do
        expect(prev_enrollment.ineligible_for_termination?(new_effective_on)).to be_falsey
      end
    end

    context "when:
      - enrollment is of kind individual market
      - enrollment is not terminated
      - enrollment has terminated_on
      - new effective exists
      - new effective on is one day after the enrollment's terminated_on
      " do

      let(:aasm_state) { 'coverage_selected' }

      it 'returns false' do
        expect(prev_enrollment.ineligible_for_termination?(new_effective_on)).to be_falsey
      end
    end

    context "when:
      - enrollment is of kind individual market
      - enrollment is terminated
      - enrollment does not have terminated_on
      - new effective exists
      - new effective on is one day after the enrollment's terminated_on
      " do

      let(:terminated_on) { nil }

      it 'returns false' do
        expect(prev_enrollment.ineligible_for_termination?(new_effective_on)).to be_falsey
      end
    end

    context "when:
      - enrollment is of kind individual market
      - enrollment is terminated
      - enrollment has terminated_on
      - new effective does not exist
      - new effective on is one day after the enrollment's terminated_on
      " do

      let(:new_effective_on) { nil }

      it 'returns false' do
        expect(prev_enrollment.ineligible_for_termination?(new_effective_on)).to be_falsey
      end
    end

    context "when:
      - enrollment is of kind individual market
      - enrollment is terminated
      - enrollment has terminated_on
      - new effective exists
      - previous day of the new effective on is greater than the enrollment's terminated_on
      " do

      let(:new_effective_on) { Date.new(system_year, 5) }

      it 'returns true' do
        expect(prev_enrollment.ineligible_for_termination?(new_effective_on)).to be_truthy
      end
    end

    context "when:
      - enrollment is of kind individual market
      - enrollment is terminated
      - enrollment has terminated_on
      - new effective exists
      - previous day of the new effective on is less than the enrollment's terminated_on
      " do

      let(:new_effective_on) { Date.new(system_year, 1) }

      it 'returns false' do
        expect(prev_enrollment.ineligible_for_termination?(new_effective_on)).to be_falsey
      end
    end
  end

  describe '#propogate_terminate' do
    let(:aasm_state) { 'coverage_terminated' }

    context 'without arguments' do
      it 'assigns terminated_on without raising any error' do
        expect { hbx_enrollment.propogate_terminate }.not_to raise_error(StandardError)
        expect(hbx_enrollment.terminated_on).to be_truthy
      end
    end

    context 'with only terminated_on' do
      let(:terminated_on_date) { hbx_enrollment.effective_on.end_of_month }

      it 'assigns terminated_on without raising any error' do
        expect do
          hbx_enrollment.propogate_terminate(terminated_on_date)
        end.not_to raise_error(StandardError)
        expect(hbx_enrollment.terminated_on).to eq(terminated_on_date)
      end
    end

    context 'with terminated_on and additional transition args' do
      let(:terminated_on_date) { hbx_enrollment.effective_on.end_of_month }
      let(:transition_args) { { reason: Enrollments::TerminationReasons::SUPERSEDED_SILENT } }

      it 'assigns terminated_on without raising any error' do
        expect do
          hbx_enrollment.propogate_terminate(terminated_on_date, transition_args)
        end.not_to raise_error(StandardError)
        expect(hbx_enrollment.terminated_on).to eq(terminated_on_date)
      end
    end
  end

  describe '#predecessor_enrollment_hbx_id' do
    let(:enrollment2) do
      FactoryBot.create(
        :hbx_enrollment,
        :individual_aptc,
        :with_silver_health_product,
        aasm_state: aasm_state,
        family: family,
        consumer_role_id: person.consumer_role.id
      )
    end

    context 'with predecessor_enrollment_id' do
      let(:predecessor_enrollment_id) { enrollment2.id }

      it 'returns predecessor_enrollment_id' do
        expect(hbx_enrollment.predecessor_enrollment_hbx_id).to eq(enrollment2.hbx_id)
      end
    end

    context 'without predecessor_enrollment_id' do
      it 'returns nil' do
        expect(hbx_enrollment.predecessor_enrollment_hbx_id).to be_nil
      end
    end
  end

  describe '#predecessor_enrollment' do
    let(:enrollment2) do
      FactoryBot.create(
        :hbx_enrollment,
        :individual_aptc,
        :with_silver_health_product,
        aasm_state: aasm_state,
        family: family,
        consumer_role_id: person.consumer_role.id
      )
    end

    context 'with predecessor_enrollment_id' do
      let(:predecessor_enrollment_id) { enrollment2.id }

      it 'returns predecessor_enrollment_id' do
        expect(hbx_enrollment.predecessor_enrollment).to eq(enrollment2)
      end
    end

    context 'without predecessor_enrollment_id' do
      it 'returns nil' do
        expect(hbx_enrollment.predecessor_enrollment).to be_nil
      end
    end
  end

  describe '#mark_purchase_event_as_published!' do
    context 'with purchase_event_published_at' do
      let(:purchase_event_published_at) { DateTime.now }

      it 'returns without modifying the published at' do
        expect(hbx_enrollment.purchase_event_published_at).to eq(purchase_event_published_at)
        hbx_enrollment.mark_purchase_event_as_published!
        expect(hbx_enrollment.purchase_event_published_at).to eq(purchase_event_published_at)
      end
    end

    context 'without purchase_event_published_at' do

      it 'populates published at' do
        expect(hbx_enrollment.purchase_event_published_at).to be_nil
        hbx_enrollment.mark_purchase_event_as_published!
        expect(hbx_enrollment.purchase_event_published_at).not_to be_nil
      end
    end
  end
end
