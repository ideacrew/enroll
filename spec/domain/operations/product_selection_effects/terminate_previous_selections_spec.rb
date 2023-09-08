# frozen_string_literal: true

require 'rails_helper'

describe Operations::ProductSelectionEffects::TerminatePreviousSelections, dbclean: :after_each do
  subject { described_class.call(product_selection) }

  describe ".call" do
    let(:coverage_year) { Date.today.year }
    let(:person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
    let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
    let(:new_enrollment_effective_on) { Date.new(coverage_year, 3) }
    let(:new_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        :individual_unassisted,
                        :with_silver_health_product,
                        :with_enrollment_members,
                        enrollment_members: family.family_members,
                        household: family.active_household,
                        effective_on: new_enrollment_effective_on,
                        family: family)
    end

    let(:previous_enrollment_effective_on) { Date.new(coverage_year, 2) }

    let(:previous_enrollment_terminated_on) { previous_enrollment_effective_on.end_of_month }

    let(:previous_enrollment_aasm_state) { 'coverage_terminated' }

    let(:previous_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        :individual_unassisted,
                        :with_silver_health_product,
                        :with_enrollment_members,
                        enrollment_members: family.family_members,
                        aasm_state: previous_enrollment_aasm_state,
                        household: family.active_household,
                        effective_on: previous_enrollment_effective_on,
                        family: family,
                        terminated_on: previous_enrollment_terminated_on)
    end

    let(:product_selection) do
      Entities::ProductSelection.new(
        {
          enrollment: new_enrollment,
          family: new_enrollment.family,
          product: new_enrollment.product
        }
      )
    end

    let(:previous_enrollment_terminated_to_terminated_state_transition) do
      previous_enrollment.reload.workflow_state_transitions.where(
        event: 'terminate_coverage!',
        from_state: 'coverage_terminated',
        to_state: 'coverage_terminated'
      ).first
    end

    let(:prev_enr_term_to_cancel_superseded_transition) do
      previous_enrollment.reload.workflow_state_transitions.where(
        event: 'cancel_coverage_for_superseded_term!',
        from_state: 'coverage_terminated',
        to_state: 'coverage_canceled'
      ).first
    end

    before do
      previous_enrollment.generate_hbx_signature
      new_enrollment.generate_hbx_signature
    end

    # For event terminate_coverage
    context "when:
      - previous_enrollment is terminated
      - previous_enrollment has terminated_on
      - new_enrollment has effective_on
      - previous_enrollment's terminated_on is same as previous day of new_enrollment's effective_on
      " do

      it 'does not transition the previous_enrollment' do
        subject
        expect(previous_enrollment_terminated_to_terminated_state_transition).to be_nil
      end
    end

    context "when:
      - previous_enrollment is terminated
      - previous_enrollment has terminated_on
      - new_enrollment has effective_on
      - previous_enrollment's terminated_on is not same as previous day of new_enrollment's effective_on
      " do
      let(:previous_enrollment_terminated_on) { previous_enrollment_effective_on.end_of_year }

      it 'transitions the previous_enrollment' do
        subject
        expect(previous_enrollment_terminated_to_terminated_state_transition).to be_truthy
      end

      it 'updates terminated_on for previous_enrollment' do
        subject
        expect(previous_enrollment.reload.terminated_on).to eq(new_enrollment_effective_on - 1.day)
      end
    end

    # For event cancel_coverage_for_superseded_term
    context "when:
      - previous_enrollment is terminated
      - new_enrollment has effective_on
      - previous_enrollment's effective_on greater than or equal to new_enrollment's effective_on
      - RR configuration feature :cancel_superseded_terminated_enrollments is enabled
      " do

      before do
        allow(
          EnrollRegistry[:cancel_superseded_terminated_enrollments].feature
        ).to receive(:is_enabled).and_return(true)
      end

      let(:previous_enrollment_effective_on) { new_enrollment_effective_on }

      it 'transitions enrollment to canceled state' do
        subject
        expect(previous_enrollment.reload.coverage_canceled?).to be_truthy
      end

      it 'transitions enrollment via cancel_coverage_for_superseded_term' do
        subject
        expect(prev_enr_term_to_cancel_superseded_transition).to be_truthy
      end
    end

    context 'for silent superseded enrollments' do
      let(:enrollment3) do
        FactoryBot.create(:hbx_enrollment, :individual_unassisted, :with_silver_health_product, :with_enrollment_members,
                          enrollment_members: family.family_members, aasm_state: 'coverage_terminated',
                          household: family.active_household, effective_on: Date.new(coverage_year, 3), family: family,
                          terminated_on: previous_enrollment_terminated_on)
      end

      let(:enrollment4) do
        FactoryBot.create(:hbx_enrollment, :individual_unassisted, :with_silver_health_product, :with_enrollment_members,
                          enrollment_members: family.family_members, aasm_state: 'coverage_selected',
                          household: family.active_household, effective_on: Date.new(coverage_year, 4), family: family,
                          terminated_on: previous_enrollment_terminated_on)
      end

      let(:enrollment5) do
        FactoryBot.create(:hbx_enrollment, :individual_unassisted, :with_silver_health_product, :with_enrollment_members,
                          enrollment_members: family.family_members, aasm_state: 'coverage_terminated',
                          household: family.active_household, effective_on: Date.new(coverage_year, 5), family: family,
                          terminated_on: previous_enrollment_terminated_on)
      end

      let(:metadata_query) { { 'metadata.reason' => 'SILENT_SUPERSEDE' } }

      before do
        allow(
          EnrollRegistry[:cancel_superseded_terminated_enrollments].feature
        ).to receive(:is_enabled).and_return(true)

        allow(
          EnrollRegistry[:silent_transition_enrollment].feature
        ).to receive(:is_enabled).and_return(true)

        [enrollment5, enrollment3, enrollment4].each(&:generate_hbx_signature)

        subject
      end

      context "when:
        - previous_enrollment is coverage_selected
        - RR configuration feature :cancel_superseded_terminated_enrollments is enabled
        - RR configuration feature :silent_transition_enrollment is enabled
        - enrollments exists with same enrollment signature
        - enrollemnts exists with same coverage_kind
        - enrollments exists with same plan_year effective dates
        " do

        let(:new_enrollment_effective_on) { Date.new(coverage_year, 1) }
        let(:previous_enrollment_effective_on) { Date.new(coverage_year, 1) }
        let(:previous_enrollment_aasm_state) { 'coverage_selected' }
        let(:previous_enrollment_terminated_on) { new_enrollment_effective_on.end_of_month }

        it 'does not add metadata as this is first enrollment' do
          expect(
            previous_enrollment.workflow_state_transitions.where(metadata_query).first
          ).to be_falsey
        end

        it 'adds metadata as this is not first enrollment' do
          expect(
            enrollment3.reload.workflow_state_transitions.where(metadata_query).first
          ).to be_truthy
        end

        it 'adds metadata as this is not first enrollment' do
          expect(
            enrollment4.reload.workflow_state_transitions.where(metadata_query).first
          ).to be_truthy
        end

        it 'adds metadata as this is not first enrollment' do
          expect(
            enrollment5.reload.workflow_state_transitions.where(metadata_query).first
          ).to be_truthy
        end
      end

      context "when:
        - previous_enrollment is coverage_terminated
        - RR configuration feature :cancel_superseded_terminated_enrollments is enabled
        - RR configuration feature :silent_transition_enrollment is enabled
        - enrollments exists with same enrollment signature
        - enrollemnts exists with same coverage_kind
        - enrollments exists with same plan_year effective dates
        " do

        let(:new_enrollment_effective_on) { Date.new(coverage_year, 2) }
        let(:previous_enrollment_effective_on) { Date.new(coverage_year, 1) }
        let(:previous_enrollment_terminated_on) { new_enrollment_effective_on.end_of_month }

        it 'does not add metadata as this is first enrollment' do
          expect(
            previous_enrollment.workflow_state_transitions.where(metadata_query).first
          ).to be_falsey
        end

        it 'adds metadata as this is not first enrollment' do
          expect(
            enrollment3.reload.workflow_state_transitions.where(metadata_query).first
          ).to be_truthy
        end

        it 'adds metadata as this is not first enrollment' do
          expect(
            enrollment4.reload.workflow_state_transitions.where(metadata_query).first
          ).to be_truthy
        end

        it 'adds metadata as this is not first enrollment' do
          expect(
            enrollment5.reload.workflow_state_transitions.where(metadata_query).first
          ).to be_truthy
        end
      end
    end
  end
end
