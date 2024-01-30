require "rails_helper"

RSpec.describe Insured::PlanShopping::PayNowHelper, :type => :helper do
  let(:person) { FactoryBot.create(:person, :with_consumer_role, :with_family) }
  let!(:hbx_profile) { FactoryBot.create(:hbx_profile) }
  let(:family) { person.primary_family }
  let(:household) { family.active_household }
  let(:individual_plans) { FactoryBot.create_list(:plan, 5, :with_premium_tables, market: 'individual') }

  describe "Carrier with payment options" do
    let!(:issuer_profile)  { FactoryBot.create(:benefit_sponsors_organizations_issuer_profile, :kaiser_profile) }
    let(:product) do
      FactoryBot.create(:benefit_markets_products_health_products_health_product,
                        title: 'IVL Test Plan Silver',
                        benefit_market_kind: :aca_individual,
                        kind: 'health',
                        deductible: 2000,
                        metal_level_kind: "silver",
                        csr_variant_id: "01",
                        issuer_profile: issuer_profile)
    end

    HbxEnrollment::INSURANCE_KINDS.each do |market|
      context "#{market} market" do
        let!(:hbx_enrollment) do
          FactoryBot.create(:hbx_enrollment,
                            :with_enrollment_members,
                            family: family,
                            enrollment_members: family.family_members,
                            household: household,
                            product: product,
                            effective_on: TimeKeeper.date_of_record.beginning_of_year,
                            kind: market)
        end

        before :each do
          assign(:enrollment, hbx_enrollment)
        end
        it "returns #{market.in?(['individual', 'coverall'])} for #{market} + Kaiser" do
          allow(helper).to receive(:has_any_previous_enrollments?).with(hbx_enrollment).and_return false
          expect(helper.show_pay_now?("Plan Shopping", hbx_enrollment)).to be_falsey
        end
      end
    end
  end

  describe "Carrier with NO payment options" do
    let!(:issuer_profile)  { FactoryBot.create(:benefit_sponsors_organizations_issuer_profile, :kaiser_profile) }
    let(:product) do
      FactoryBot.create(:benefit_markets_products_health_products_health_product,
                        title: 'IVL Test Plan Silver',
                        benefit_market_kind: :aca_individual,
                        kind: 'health',
                        deductible: 2000,
                        metal_level_kind: "silver",
                        csr_variant_id: "01",
                        issuer_profile: issuer_profile)
    end
    let!(:hbx_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        :with_enrollment_members,
                        family: family,
                        enrollment_members: family.family_members,
                        household: household,
                        product: product,
                        effective_on: TimeKeeper.date_of_record.beginning_of_year,
                        kind: 'individual')
    end
    before :each do
      assign(:enrollment, hbx_enrollment)
    end
    it "returns false for not Kaiser" do
      expect(helper.show_pay_now?("Plan Shopping", hbx_enrollment)).to be_falsey
    end
  end

  describe "Check family has Kaiser enrollments or not" do
    let!(:issuer_profile)  { FactoryBot.create(:benefit_sponsors_organizations_issuer_profile, :kaiser_profile) }
    let(:product) do
      FactoryBot.create(:benefit_markets_products_health_products_health_product,
                        title: 'IVL Test Plan Silver',
                        benefit_market_kind: :aca_individual,
                        kind: 'health',
                        deductible: 2000,
                        metal_level_kind: "silver",
                        csr_variant_id: "01",
                        issuer_profile: issuer_profile)
    end
    let!(:hbx_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        :with_enrollment_members,
                        family: family,
                        enrollment_members: family.family_members,
                        household: household,
                        product: product,
                        effective_on: TimeKeeper.date_of_record.beginning_of_year + 1.month,
                        kind: 'individual')
    end

    let!(:hbx_enrollment1) do
      FactoryBot.create(:hbx_enrollment,
                        :with_enrollment_members,
                        family: family,
                        enrollment_members: family.family_members,
                        household: household,
                        product: product,
                        effective_on: TimeKeeper.date_of_record.beginning_of_year,
                        kind: 'individual')
    end
    before :each do
      assign(:enrollment, hbx_enrollment)
      @carrier_key = helper.fetch_carrier_key_from_legal_name(hbx_enrollment&.product&.issuer_profile&.legal_name)
    end

    it 'return true if household has kaiser enrollments in current benefit coverage period with same subscriber' do
      expect(helper.has_any_previous_enrollments?(hbx_enrollment)).to eq true
    end

    it 'return false previous enrollment is shopping state' do
      hbx_enrollment1.update_attributes(aasm_state: 'shopping')
      hbx_enrollment.update_attributes(effective_on: TimeKeeper.date_of_record.last_year)
      expect(helper.has_any_previous_enrollments?(hbx_enrollment)).to eq false
    end

    it 'return false previous enrollment is canceled state' do
      hbx_enrollment1.update_attributes(aasm_state: 'coverage_canceled')
      hbx_enrollment.update_attributes(effective_on: TimeKeeper.date_of_record.last_year)
      expect(helper.has_any_previous_enrollments?(hbx_enrollment)).to eq false
    end

    it 'return false previous enrollment is inactive state' do
      hbx_enrollment1.update_attributes(aasm_state: 'inactive')
      hbx_enrollment.update_attributes(effective_on: TimeKeeper.date_of_record.last_year)
      expect(helper.has_any_previous_enrollments?(hbx_enrollment)).to eq false
    end

    it 'return false previous enrollment has no subscriber' do
      hbx_enrollment1.hbx_enrollment_members.detect(&:is_subscriber).update_attributes(is_subscriber: false)
      hbx_enrollment.update_attributes(effective_on: TimeKeeper.date_of_record.last_year)
      expect(helper.has_any_previous_enrollments?(hbx_enrollment)).to eq false
    end

    it 'return false previous enrollment has no product' do
      hbx_enrollment1.unset(:product_id)
      hbx_enrollment.update_attributes(effective_on: TimeKeeper.date_of_record.last_year)
      expect(helper.has_any_previous_enrollments?(hbx_enrollment)).to eq false
    end

    it 'return false if household has kaiser enrollments in current benefit coverage period' do
      hbx_enrollment.update_attributes(kind: "employer_sponsored")
      hbx_enrollment1.update_attributes(kind: "employer_sponsored")
      expect(helper.has_any_previous_enrollments?(hbx_enrollment)).to eq false
    end

    it 'return false if household has kaiser enrollments in a previous benefit coverage period year' do
      hbx_enrollment1.update_attributes(effective_on: TimeKeeper.date_of_record.last_year)
      expect(helper.has_any_previous_enrollments?(hbx_enrollment)).to eq false
    end

    it 'return false if household had no previous kaiser enrollments in current benefit coverage period' do
      hbx_enrollment1.update_attributes(product_id: "")
      expect(helper.has_any_previous_enrollments?(hbx_enrollment)).to eq false
    end

    it 'should return false if enrollments do not have product' do
      hbx_enrollment.update_attributes(product_id: "")
      hbx_enrollment1.update_attributes(product_id: "")
      expect(helper.has_any_previous_enrollments?(hbx_enrollment)).to eq false
    end

    it 'should return false if previous enrollments are different kinds' do
      hbx_enrollment1.update_attributes(coverage_kind: "dental")
      expect(helper.has_any_previous_enrollments?(hbx_enrollment)).to eq false
    end
  end

  describe 'Whether family has break in coverage enrollments' do
    let!(:issuer_profile)  { FactoryBot.create(:benefit_sponsors_organizations_issuer_profile, :kaiser_profile) }
    let(:product) do
      FactoryBot.create(:benefit_markets_products_health_products_health_product,
                        title: 'IVL Test Plan Silver',
                        benefit_market_kind: :aca_individual,
                        kind: 'health',
                        deductible: 2000,
                        metal_level_kind: "silver",
                        csr_variant_id: "01",
                        issuer_profile: issuer_profile)
    end
    let!(:hbx_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        :with_enrollment_members,
                        family: family,
                        enrollment_members: family.family_members,
                        household: household,
                        product: product,
                        effective_on: TimeKeeper.date_of_record.beginning_of_year + 1.month,
                        kind: 'individual')
    end

    let!(:hbx_enrollment1) do
      FactoryBot.create(:hbx_enrollment,
                        :with_enrollment_members,
                        family: family,
                        enrollment_members: family.family_members,
                        household: household,
                        product: product,
                        effective_on: TimeKeeper.date_of_record.beginning_of_year,
                        kind: 'individual')
    end

    before :each do
      assign(:enrollment, hbx_enrollment)
    end

    it 'should return true if there is a break in coverage' do
      hbx_enrollment1.update_attributes(aasm_state: 'coverage_terminated', terminated_on: TimeKeeper.date_of_record.beginning_of_year + 10.days)
      expect(helper.has_break_in_coverage_enrollments?(hbx_enrollment)).to eq true
    end

    it 'should return false if there is a no break in coverage' do
      hbx_enrollment1.update_attributes(aasm_state: 'coverage_terminated', terminated_on: TimeKeeper.date_of_record.beginning_of_year + 1.month)
      expect(helper.has_break_in_coverage_enrollments?(hbx_enrollment)).to eq false
    end

    it 'should return false if there is a terminated enrollment in previous year' do
      hbx_enrollment1.update_attributes(aasm_state: 'coverage_terminated', terminated_on: TimeKeeper.date_of_record.last_year)
      expect(helper.has_break_in_coverage_enrollments?(hbx_enrollment)).to eq false
    end

    it 'should return false if there is a break in coverage less than 1 day' do
      hbx_enrollment1.update_attributes(aasm_state: 'coverage_terminated', terminated_on: TimeKeeper.date_of_record.beginning_of_year)
      hbx_enrollment.update_attributes(effective_on: TimeKeeper.date_of_record.beginning_of_year + 1.day)
      expect(helper.has_break_in_coverage_enrollments?(hbx_enrollment)).to eq false
    end

    it 'should return false if erollments are in expired or unverified or void' do
      hbx_enrollment1.update_attributes(aasm_state: 'coverage_expired')
      hbx_enrollment.update_attributes(aasm_state: "unverified")
      expect(helper.has_break_in_coverage_enrollments?(hbx_enrollment)).to eq false
    end
  end

  describe 'Pay Now button should be available only for limited time' do
    let!(:issuer_profile)  { FactoryBot.create(:benefit_sponsors_organizations_issuer_profile, :kaiser_profile) }
    let(:product) do
      FactoryBot.create(:benefit_markets_products_health_products_health_product,
                        title: 'IVL Test Plan Silver',
                        benefit_market_kind: :aca_individual,
                        kind: 'health',
                        deductible: 2000,
                        metal_level_kind: "silver",
                        csr_variant_id: "01",
                        issuer_profile: issuer_profile)
    end
    let!(:hbx_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        :with_enrollment_members,
                        family: family,
                        enrollment_members: family.family_members,
                        household: household,
                        product: product,
                        effective_on: TimeKeeper.date_of_record.beginning_of_year + 1.month,
                        kind: 'individual')
    end

    let!(:hbx_enrollment1) do
      FactoryBot.create(:hbx_enrollment,
                        :with_enrollment_members,
                        family: family,
                        enrollment_members: family.family_members,
                        household: household,
                        product: product,
                        effective_on: TimeKeeper.date_of_record.beginning_of_year,
                        kind: 'individual')
    end

    context "for renewing coverage_selected" do
      before :each do
        hbx_enrollment.workflow_state_transitions << WorkflowStateTransition.new(
          from_state: hbx_enrollment.aasm_state,
          to_state: "renewing_coverage_selected"
        )
        hbx_enrollment.update_attributes(effective_on: TimeKeeper.date_of_record + 1.day)
        assign(:enrollment, hbx_enrollment)
      end

      it 'should return true if transition time is greater 15 minutes' do
        hbx_enrollment.workflow_state_transitions.first.update_attributes(transition_at: TimeKeeper.date_of_record - 20.minutes)
        expect(helper.pay_now_button_timed_out?(hbx_enrollment)).to eq true
      end

      it 'should return true if transition is not found' do
        hbx_enrollment.workflow_state_transitions.first.update_attributes(to_state: "auto_renewing")
        expect(helper.pay_now_button_timed_out?(hbx_enrollment)).to eq true
      end

      it 'should return false if transition time is within 15 minutes' do
        hbx_enrollment.workflow_state_transitions.first.update_attributes(transition_at: TimeKeeper.date_of_record - 10.minutes)
        expect(helper.pay_now_button_timed_out?(hbx_enrollment)).to eq true
      end
    end

    context "for coverage_selected" do
      before :each do
        hbx_enrollment.workflow_state_transitions << WorkflowStateTransition.new(
          from_state: hbx_enrollment.aasm_state,
          to_state: "coverage_selected"
        )
        hbx_enrollment.update_attributes(effective_on: TimeKeeper.date_of_record + 1.day)
        assign(:enrollment, hbx_enrollment)
      end

      it 'should return true if transition time is greater 15 minutes' do
        hbx_enrollment.workflow_state_transitions.first.update_attributes(transition_at: TimeKeeper.date_of_record - 20.minutes)
        expect(helper.pay_now_button_timed_out?(hbx_enrollment)).to eq true
      end

      it 'should return true if transition is not found' do
        hbx_enrollment.workflow_state_transitions.first.update_attributes(to_state: "auto_renewing")
        expect(helper.pay_now_button_timed_out?(hbx_enrollment)).to eq true
      end

      it 'should return false if transition time is within 15 minutes' do
        hbx_enrollment.workflow_state_transitions.first.update_attributes(transition_at: TimeKeeper.date_of_record - 10.minutes)
        expect(helper.pay_now_button_timed_out?(hbx_enrollment)).to eq true
      end
    end
  end

  describe 'Pay Now button on enrollment tile' do
    let!(:issuer_profile)  { FactoryBot.create(:benefit_sponsors_organizations_issuer_profile, :kaiser_profile) }
    let(:product) do
      FactoryBot.create(:benefit_markets_products_health_products_health_product,
                        title: 'IVL Test Plan Silver',
                        benefit_market_kind: :aca_individual,
                        kind: 'health',
                        deductible: 2000,
                        metal_level_kind: "silver",
                        csr_variant_id: "01",
                        issuer_profile: issuer_profile)
    end
    let!(:hbx_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        :with_enrollment_members,
                        family: family,
                        enrollment_members: family.family_members,
                        household: household,
                        product: product,
                        effective_on: TimeKeeper.date_of_record.beginning_of_year + 1.month,
                        kind: 'individual')
    end

    let!(:hbx_enrollment1) do
      FactoryBot.create(:hbx_enrollment,
                        :with_enrollment_members,
                        family: family,
                        enrollment_members: family.family_members,
                        household: household,
                        product: product,
                        effective_on: TimeKeeper.date_of_record.beginning_of_year,
                        kind: 'employer_sponsored')
    end

    before :each do
      hbx_enrollment.workflow_state_transitions << WorkflowStateTransition.new(
        from_state: hbx_enrollment.aasm_state,
        to_state: "coverage_selected"
      )
      assign(:enrollment, hbx_enrollment)
    end

    it 'should return false if enrollment kind is employer sponsored' do
      allow(hbx_enrollment).to receive(:is_shop?).and_return(true)
      expect(helper.show_pay_now?("Enrollment Tile", hbx_enrollment1)).to be_falsey
    end

    it 'should show if generic redirect is enabled' do
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:generic_redirect).and_return(true)
      allow(EnrollRegistry[:generic_redirect].setting(:strict_tile_check)).to receive(:item).and_return(false)
      expect(helper.show_generic_redirect?(hbx_enrollment)).to eq true
    end

    it 'should return false if strict generic redirect is enabled and enrollment tile is disabled' do
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:generic_redirect).and_return(true)
      allow(EnrollRegistry[:generic_redirect].setting(:strict_tile_check)).to receive(:item).and_return(true)
      allow(EnrollRegistry[:kaiser_pay_now].setting(:enrollment_tile)).to receive(:item).and_return(false)
      allow(EnrollRegistry[:kaiser_permanente_pay_now].setting(:enrollment_tile)).to receive(:item).and_return(false)
      expect(helper.show_generic_redirect?(hbx_enrollment)).to be_falsey
    end
  end
end
