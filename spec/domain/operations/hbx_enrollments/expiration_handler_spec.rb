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
    JSON.parse(
      {
        'aasm_state': { '$in': HbxEnrollment::ENROLLED_STATUSES - ['coverage_termination_pending'] },
        'effective_on': { '$lt': start_on },
        'kind': { '$in': ['individual', 'coverall'] }
      }.to_json
    ).deep_symbolize_keys
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

  # TODO: Refactor to get the logger content from subject.logger instead of hardcoding the path
  let(:logger_content) do
    File.read("#{Rails.root}/log/expiration_handler_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
  end

  describe 'with invalid params' do
    context 'params is not a hash' do
      let(:params) { 'bad params' }
      let(:failure_msg) { "Invalid input params: #{params}. Expected a hash." }

      it 'returns failure monad due to invalid params type' do
        expect(result.failure).to eq(failure_msg)
        expect(logger_content).to match(failure_msg)
      end
    end

    context 'missing query criteria' do
      let(:params) { {} }
      let(:failure_msg) { "Invalid query_criteria in params: #{params}. Expected a hash." }

      it 'fails due to missing query criteria' do
        expect(result.failure).to eq(failure_msg)
        expect(logger_content).to match(failure_msg)
      end
    end

    context 'with invalid transmittable_identifiers' do
      let(:params) { { query_criteria: {}, transmittable_identifiers: nil } }
      let(:failure_msg) { "Invalid transmittable_identifiers in params: #{params}. Expected a hash." }

      it 'returns failure monad with error message' do
        expect(result.failure).to eq(failure_msg)
        expect(logger_content).to match(failure_msg)
      end
    end

    context 'with missing job_gid' do
      let(:params) { { query_criteria: {}, transmittable_identifiers: {} } }
      let(:failure_msg) { "Missing job_gid in transmittable_identifiers of params: #{params}." }

      it 'returns failure monad with error message' do
        expect(result.failure).to eq(failure_msg)
        expect(logger_content).to match(failure_msg)
      end
    end

    context 'with no enrollments in previous year' do
      let(:effective_on) { TimeKeeper.date_of_record.beginning_of_year }

      it 'returns a failure moand with error message' do
        expect(result.failure).to eq("No enrollments found for query criteria: #{query_criteria}")
        expect(logger_content).to match(/No enrollments found for query criteria:/)
      end
    end

    context 'with no active enrollments in previous year' do
      let(:aasm_state) { 'coverage_canceled' }

      it 'returns a failure moand with error message' do
        expect(result.failure).to eq("No enrollments found for query criteria: #{query_criteria}")
        expect(logger_content).to match(/No enrollments found for query criteria:/)
      end
    end
  end

  describe 'with valid params' do
    let(:success_msg) do
      "Done publishing enrollment expiration events. See hbx_enrollments_expiration_handler log for results."
    end

    let(:enr_success_msg) do
      "Successfully published expiration event: events.individual.enrollments.expire_coverages.expire for enrollment with hbx_id: #{enrollment.hbx_id}."
    end

    it 'succeeds with message' do
      expect(result.success).to eq(success_msg)
      expect(logger_content).to match(enr_success_msg)
      expect(logger_content).to match(success_msg)
    end
  end

  after :all do
    file_path = "#{Rails.root}/log/expiration_handler_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
    File.delete(file_path) if File.file?(file_path)
  end
end
