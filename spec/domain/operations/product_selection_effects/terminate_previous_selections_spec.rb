# frozen_string_literal: true

require 'rails_helper'
require File.join(Rails.root, 'spec/shared_contexts/dchbx_product_selection')

RSpec.describe ::Operations::ProductSelectionEffects::TerminatePreviousSelections, dbclean: :after_each do
  let(:current_year) { TimeKeeper.date_of_record.year }

  describe '.call' do
    context 'with terminated predecessor enrollment' do
      include_context 'family with one member and one enrollment and one renewal enrollment'

      before do
        enrollment.terminate_coverage(TimeKeeper.date_of_record.end_of_month)
        enrollment.save
        allow(successor_enrollment).to receive(:same_signatures).with(enrollment).and_return(true)
      end

      it 'should not terminate a previously terminated enrollment' do
        expect(enrollment.workflow_state_transitions.count).to eq(1)
        subject.call(Entities::ProductSelection.new({ enrollment: successor_enrollment, product: product, family: family }))
        expect(enrollment.reload.workflow_state_transitions.count).to eq(1)
      end
    end
  end
end
