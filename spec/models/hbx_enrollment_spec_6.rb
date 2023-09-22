# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HbxEnrollment, type: :model do
  before :all do
    DatabaseCleaner.clean
  end

  let(:coverage_year) { Date.today.year }
  let(:person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
  let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let(:start_of_month) { TimeKeeper.date_of_record.beginning_of_month }
  let(:silver_product) { FactoryBot.create(:benefit_markets_products_health_products_health_product, :silver) }
  let(:enrollment1) do
    FactoryBot.create(:hbx_enrollment,
                      :individual_unassisted,
                      :with_enrollment_members,
                      coverage_kind: 'health',
                      product_id: silver_product.id,
                      enrollment_members: family.family_members,
                      household: family.active_household,
                      effective_on: start_of_month,
                      family: family)
  end
  let(:effective_year) { enrollment1.effective_on.year }

  let(:enrollment2) do
    FactoryBot.create(:hbx_enrollment,
                      :individual_unassisted,
                      :with_enrollment_members,
                      coverage_kind: 'health',
                      product_id: silver_product.id,
                      enrollment_members: family.family_members,
                      household: family.active_household,
                      effective_on: start_of_month,
                      family: family)
  end

  let(:coverage_kind) { 'health' }
  let(:effective_on) { start_of_month }
  let(:aasm_state) { 'coverage_selected' }
  let(:kind) { 'individual' }
  let(:terminate_reason) { nil }
  let(:enrollment3) do
    FactoryBot.create(:hbx_enrollment,
                      :individual_unassisted,
                      :with_enrollment_members,
                      coverage_kind: coverage_kind,
                      effective_on: effective_on,
                      aasm_state: aasm_state,
                      kind: kind,
                      terminate_reason: terminate_reason,
                      product_id: silver_product.id,
                      enrollment_members: family.family_members,
                      household: family.active_household,
                      family: family)
  end

  describe '#previous_enrollments' do
    let(:result_enr_ids) { enrollment1.previous_enrollments(effective_year).pluck(:id) }

    before { [enrollment2, enrollment3].each(&:generate_hbx_signature) }

    context 'with different coverage_kind' do
      let(:coverage_kind) { 'dental' }

      it 'does not include enrollment3' do
        expect(result_enr_ids).to include(enrollment2.id)
        expect(result_enr_ids).not_to include(enrollment3.id)
      end
    end

    context 'with different effective_on' do
      let(:effective_on) { TimeKeeper.date_of_record.next_year.beginning_of_month }

      it 'does not include enrollment3' do
        expect(result_enr_ids).to include(enrollment2.id)
        expect(result_enr_ids).not_to include(enrollment3.id)
      end
    end

    context 'with different aasm_state' do
      let(:aasm_state) { 'coverage_canceled' }

      it 'does not include enrollment3' do
        expect(result_enr_ids).to include(enrollment2.id)
        expect(result_enr_ids).not_to include(enrollment3.id)
      end
    end

    context 'with different kind' do
      let(:kind) { 'employer_sponsored' }

      it 'does not include enrollment3' do
        expect(result_enr_ids).to include(enrollment2.id)
        expect(result_enr_ids).not_to include(enrollment3.id)
      end
    end

    context 'with non pay indicator' do
      let(:aasm_state) { 'coverage_terminated' }
      let(:terminate_reason) { HbxEnrollment::TermReason::NON_PAYMENT }

      it 'does not include enrollment3' do
        expect(result_enr_ids).to include(enrollment2.id)
        expect(result_enr_ids).not_to include(enrollment3.id)
      end
    end

    context 'with expected info' do
      it 'includes enrollment2, enrollment3' do
        expect(result_enr_ids).to include(enrollment2.id)
        expect(result_enr_ids).to include(enrollment3.id)
      end
    end
  end
end
