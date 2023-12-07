# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::HbxEnrollments::BeginCoverageHandler, dbclean: :after_each do

  let(:family)      { FactoryBot.create(:family, :with_primary_family_member) }
  let!(:enrollment) { FactoryBot.create(:hbx_enrollment, :individual_unassisted, family: family) }

  describe 'with invalid params' do
    let(:params) { {} }
    let(:result) { described_class.new.call(params) }

    context 'missing query criteria' do
      it 'fails due to missing query criteria' do
        expect(result.success?).to be_falsey
        expect(result.failure).to eq('Missing query_criteria')
      end
    end

    context 'with invalid query criteria' do
      let(:params) { { query_criteria: 'bad query' } }
      let(:result) { described_class.new.call(params) }

      it 'fails due to invalid query' do
        expect(result.success?).to be_falsey
        expect(result.failure).to match(/Error generating enrollments_to_begin query/)
      end
    end
  end

  describe 'with valid params' do
    let(:query_criteria) do
      {
        :kind.in => ["individual", "coverall"],
        :aasm_state.in => ["auto_renewing", "renewing_coverage_selected"]
      }
    end
    let(:params) { { query_criteria: query_criteria } }
    let(:result) { described_class.new.call(params) }

    it 'succeeds with message' do
      expect(result.success?).to be_truthy
      expect(result.value!).to eq("Done publishing begin coverage enrollment events.  See hbx_enrollments_begin_coverage_handler log for results.")
    end
  end
end
