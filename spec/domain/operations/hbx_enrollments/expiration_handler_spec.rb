# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::HbxEnrollments::ExpirationHandler, dbclean: :after_each do

  let(:family)      { FactoryBot.create(:family, :with_primary_family_member) }
  let(:effective_on) { TimeKeeper.date_of_record.prev_year.beginning_of_year }
  let(:aasm_state) { 'coverage_selected' }

  let!(:enrollment) do
    FactoryBot.create(
      :hbx_enrollment,
      :individual_unassisted,
      family: family,
      aasm_state: aasm_state,
      effective_on: effective_on
    )
  end

  let(:query_criteria) do
    {
      'aasm_state': { '$in': HbxEnrollment::ENROLLED_STATUSES - ['coverage_termination_pending'] },
      'effective_on': { '$lt': start_on },
      'kind': { '$in': ['individual', 'coverall'] }
    }
  end

  let(:start_on) { TimeKeeper.date_of_record.beginning_of_year }
  let(:transmittable_job) { FactoryBot.create(:transmittable_job, :hbx_enrollments_expiration) }
  let(:transmittable_identifiers) { { job_gid: transmittable_job.to_global_id.uri } }

  let(:params) do
    {
      query_criteria: query_criteria,
      transmittable_identifiers: transmittable_identifiers
    }
  end

  let(:result) { subject.call(params) }

  describe 'with invalid params' do
    context 'params is not a hash' do
      let(:params) { 'bad params' }

      it 'returns failure monad due to invalid params type' do
        expect(result.failure).to eq("Invalid input params: #{params}. Expected a hash.")
      end
    end

    context 'missing query criteria' do
      let(:params) { {} }
      let(:failure_msg) { "Invalid query_criteria in params: #{params}. Expected a hash." }

      it 'fails due to missing query criteria' do
        expect(result.failure).to eq(failure_msg)
        expect(subject.logger)
      end
    end

    context 'with invalid transmittable_identifiers' do
      let(:params) { { query_criteria: {}, transmittable_identifiers: nil } }

      it 'returns failure monad with error message' do
        expect(result.failure).to eq("Invalid transmittable_identifiers in params: #{params}. Expected a hash.")
      end
    end

    context 'with missing job_gid' do
      let(:params) { { query_criteria: {}, transmittable_identifiers: {} } }

      it 'returns failure monad with error message' do
        expect(result.failure).to eq("Missing job_gid in transmittable_identifiers of params: #{params}.")
      end
    end

    context 'with no enrollments in previous year' do
      let(:effective_on) { TimeKeeper.date_of_record.beginning_of_year }

      it 'returns a failure moand with error message' do
        expect(result.failure).to eq("No enrollments found for query criteria: #{query_criteria}")
      end
    end

    context 'with no active enrollments in previous year' do
      let(:aasm_state) { 'coverage_canceled' }

      it 'returns a failure moand with error message' do
        expect(result.failure).to eq("No enrollments found for query criteria: #{query_criteria}")
      end
    end
  end

  describe 'with valid params' do
    it 'succeeds with message' do
      expect(result.success).to eq(
        "Done publishing enrollment expiration events. See hbx_enrollments_expiration_handler log for results."
      )
    end
  end
end
