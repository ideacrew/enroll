# frozen_string_literal: true

require "rails_helper"

RSpec.describe HbxEnrollment, "created in the shopping mode, then transitioned with a reason", dbclean: :after_each do
  let(:product) do
    FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health)
  end

  let(:family) do
    FactoryBot.create(:individual_market_family)
  end

  let(:enrollment) do
    hbx_enrollment = HbxEnrollment.new(
      :aasm_state => "shopping",
      :kind => "individual",
      :effective_on => TimeKeeper.date_of_record.beginning_of_month,
      :enrollment_kind => "open_enrollment",
      :coverage_kind => "health",
      :family => family,
      :household => family.households.first,
      :product => product
    )
    hbx_enrollment.save!
    hbx_enrollment
  end

  it "can be found using the reason when coverage is selected" do
    enrollment.select_coverage!({:reason => "aptc_update"})
    found_enrollment = HbxEnrollment.where(
      "workflow_state_transitions.metadata.reason" => "aptc_update"
    ).first
    expect(found_enrollment.id).to eq(enrollment.id)
  end

  it "can be found using the reason when coverage is canceled" do
    enrollment.select_coverage!
    enrollment.cancel_coverage!(Date.today, {:reason => Enrollments::TerminationReasons::SUPERSEDED_SILENT})
    found_enrollment = HbxEnrollment.where(
      "workflow_state_transitions.metadata.reason" => Enrollments::TerminationReasons::SUPERSEDED_SILENT
    ).first
    expect(found_enrollment.id).to eq(enrollment.id)
  end

  describe '#latest_wfst_is_superseded_silent?' do
    before do
      enrollment.select_coverage!
      enrollment.cancel_coverage!(Date.today, transition_args)
    end

    context 'without transition args during transition' do
      let(:transition_args) { {} }

      it 'returns false' do
        wfst = enrollment.workflow_state_transitions.last
        expect(enrollment.is_transition_superseded_silent?(wfst)).to be_falsey
      end
    end

    context 'with non-superseded_silent transition args during transition' do
      let(:transition_args) { { reason: 'Other than superseded silent' } }

      it 'returns false' do
        wfst = enrollment.workflow_state_transitions.last
        expect(enrollment.is_transition_superseded_silent?(wfst)).to be_falsey
      end
    end

    context 'with superseded_silent transition args during transition' do
      context 'with symbolized keys' do
        let(:transition_args) { { reason: Enrollments::TerminationReasons::SUPERSEDED_SILENT } }

        it 'returns true' do
          wfst = enrollment.workflow_state_transitions.last
          expect(enrollment.is_transition_superseded_silent?(wfst)).to be_truthy
        end
      end

      context 'with stringified keys' do
        let(:transition_args) { { 'reason' => Enrollments::TerminationReasons::SUPERSEDED_SILENT } }

        it 'returns true' do
          wfst = enrollment.workflow_state_transitions.last
          expect(enrollment.is_transition_superseded_silent?(wfst)).to be_truthy
        end
      end
    end
  end
end