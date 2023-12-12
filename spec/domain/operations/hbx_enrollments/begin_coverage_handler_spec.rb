# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::HbxEnrollments::BeginCoverageHandler, dbclean: :after_each do

  let(:family)      { FactoryBot.create(:family, :with_primary_family_member) }
  let!(:enrollment) { FactoryBot.create(:hbx_enrollment, :individual_unassisted, family: family, aasm_state: "auto_renewing") }

  describe 'with invalid params' do
    let(:result) { described_class.new.call(params) }

    context 'params is not a hash' do
      let(:params) { 'bad params' }

      it 'fails due to missing query criteria' do
        expect(result.success?).to be_falsey
        expect(result.failure).to eq('Missing query_criteria.')
      end
    end

    context 'missing query criteria' do
      let(:params) { {} }

      it 'fails due to missing query criteria' do
        expect(result.success?).to be_falsey
        expect(result.failure).to eq('Missing query_criteria.')
      end
    end

    context 'with invalid query criteria' do
      let(:params) { { query_criteria: 'bad query' } }
      let(:result) { described_class.new.call(params) }

      it 'fails due to invalid query' do
        expect(result.success?).to be_falsey
        expect(result.failure).to eq("Missing query_criteria.")
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
      expect(result.value!).to eq("Done publishing begin coverage enrollment events. See hbx_enrollments_begin_coverage_handler log for results.")
    end

    context 'with no enrollments found to begin coverage' do
      before do
        enrollment.update_attributes(aasm_state: "coverage_selected")
      end

      it 'fails due to no enrollments found' do
        expect(result.success?).to be_falsey
        expect(result.failure).to eq("No enrollments found for query criteria: #{query_criteria}")
      end
    end
  end
end
