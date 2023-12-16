# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::HbxEnrollments::BeginCoverage, dbclean: :after_each do

  let(:family)      { FactoryBot.create(:family, :with_primary_family_member) }
  let(:effective_on) { TimeKeeper.date_of_record.beginning_of_year }
  let(:aasm_state) { 'auto_renewing' }
  let(:enrollment) { FactoryBot.create(:hbx_enrollment, :individual_unassisted, family: family, aasm_state: aasm_state, effective_on: effective_on) }

  let(:enrollment_hbx_id) { enrollment.hbx_id }

  let(:operation_instance)  { described_class.new }
  let(:result)              { operation_instance.call(params) }

  let(:logger) do
    File.read("#{Rails.root}/log/begin_coverage_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
  end

  let(:job) do
    ::Operations::Transmittable::CreateJob.new.call(
      {
        key: :hbx_enrollments_begin_coverage,
        title: "Request begin coverage of all renewal IVL enrollments.",
        description: "Job that requests begin coverage of all renewal IVL enrollments.",
        publish_on: DateTime.now,
        started_at: DateTime.now
      }
    ).success
  end

  let(:request_transmission) do
    ::Operations::Transmittable::CreateTransmission.new.call(
      {
        job: job,
        key: :hbx_enrollment_begin_coverage_request,
        title: "Transmission request to begin coverage enrollment with hbx id: #{enrollment.hbx_id}.",
        description: "Transmission request to begin coverage enrollment with hbx id: #{enrollment.hbx_id}.",
        publish_on: Date.today,
        started_at: DateTime.now,
        event: 'initial',
        state_key: :initial,
        correlation_id: enrollment.hbx_id
      }
    ).success
  end

  let(:request_transaction) do
    ::Operations::Transmittable::CreateTransaction.new.call(
      {
        transmission: request_transmission,
        subject: enrollment,
        key: :hbx_enrollment_begin_coverage_request,
        title: "Enrollment begin coverage request transaction for #{enrollment.hbx_id}.",
        description: "Transaction request to begin coverage of enrollment with hbx id: #{enrollment.hbx_id}.",
        publish_on: Date.today,
        started_at: DateTime.now,
        event: 'initial',
        state_key: :initial,
        correlation_id: enrollment.hbx_id
      }
    ).success
  end

  let(:params) do
    {
      enrollment_gid: enrollment.to_global_id.uri.to_s,
      transmittable_identifiers: {
        job_gid: job.to_global_id.uri.to_s,
        transmission_gid: request_transmission.to_global_id.uri.to_s,
        transaction_gid: request_transaction.to_global_id.uri.to_s,
        subject_gid: enrollment.to_global_id.uri.to_s
      }
    }
  end

  describe 'with invalid params' do
    context 'without params' do
      let(:params) { nil }

      it 'returns failure monad' do
        expect(result.failure).to eq("Invalid input params: #{params}. Expected a hash.")
      end
    end

    context 'without transmittable_identifiers' do
      let(:params) { { enrollment_gid: enrollment.to_global_id.uri.to_s } }

      it 'returns failure monad' do
        expect(result.failure).to eq("Invalid transmittable_identifiers in params: #{params}. Expected a hash.")
      end
    end

    context 'without enrollment_gid' do
      let(:params) do
        {
          transmittable_identifiers: {
            job_gid: job.to_global_id.uri.to_s,
            transmission_gid: request_transmission.to_global_id.uri.to_s,
            transaction_gid: request_transaction.to_global_id.uri.to_s,
            subject_gid: enrollment.to_global_id.uri.to_s
          }
        }
      end

      it 'returns failure monad' do
        expect(result.failure).to eq("Missing enrollment_gid in params: #{params}.")
      end
    end

    context 'without job_gid' do
      let(:params) { { enrollment_gid: enrollment.to_global_id.uri.to_s, transmittable_identifiers: {} } }

      it 'returns failure monad' do
        expect(result.failure).to eq("Missing job_gid in transmittable_identifiers of params: #{params}.")
      end
    end

    context 'without transmission_gid' do
      let(:params) do
        {
          enrollment_gid: enrollment.to_global_id.uri.to_s,
          transmittable_identifiers: {
            job_gid: job.to_global_id.uri.to_s,
            transaction_gid: request_transaction.to_global_id.uri.to_s
          }
        }
      end

      it 'returns failure monad' do
        expect(result.failure).to eq("Missing transmission_gid in transmittable_identifiers of params: #{params}.")
      end
    end

    context 'without transaction_gid' do
      let(:params) do
        {
          enrollment_gid: enrollment.to_global_id.uri.to_s,
          transmittable_identifiers: {
            job_gid: job.to_global_id.uri.to_s,
            transmission_gid: request_transmission.to_global_id.uri.to_s
          }
        }
      end

      it 'returns failure monad' do
        expect(result.failure).to eq("Missing transaction_gid in transmittable_identifiers of params: #{params}.")
      end
    end

    context 'without subject_gid' do
      let(:params) do
        {
          enrollment_gid: enrollment.to_global_id.uri.to_s,
          transmittable_identifiers: {
            job_gid: job.to_global_id.uri.to_s,
            transmission_gid: request_transmission.to_global_id.uri.to_s,
            transaction_gid: request_transaction.to_global_id.uri.to_s
          }
        }
      end

      it 'returns failure monad' do
        expect(result.failure).to eq("Missing subject_gid in transmittable_identifiers of params: #{params}.")
      end
    end
  end

  describe 'with valid params' do
    it 'returns success message' do
      msg = "Successfully began coverage for enrollment hbx id #{enrollment.hbx_id}."
      expect(result.success).to eq(msg)
      expect(logger).to include(msg)
    end

    it 'creates transmission with correct association' do
      expect(operation_instance.response_transmission).to be_a(::Transmittable::Transmission)
      expect(operation_instance.response_transmission.job).to eq(transmittable_job)
    end

    it 'associates newly created response transmission to job' do
      expect(transmittable_job.transmissions.count).to eq(2)
      expect(transmittable_job.transmissions.pluck(:key)).to include(:hbx_enrollment_begin_coverage_response)
    end

    it 'creates response transaction with correct associations' do
      expect(operation_instance.response_transaction).to be_a(::Transmittable::Transaction)
      expect(operation_instance.response_transaction.transactable).to eq(enrollment)
    end

    it 'creates join table record between transmission and transaction' do
      expect(
        ::Transmittable::TransactionsTransmissions.where(
          transaction_id: operation_instance.response_transaction.id,
          transmission_id: operation_instance.response_transmission.id
        ).count
      ).to eq(1)
    end

    it 'associates both request/response transmission and transaction to enrollment' do
      request_transmission_transmission_id = operation_instance.request_transmission.transmission_id
      response_transmission_transmission_id = operation_instance.response_transmission.transmission_id
      request_transaction_transaction_id = operation_instance.request_transaction.transaction_id
      response_transaction_transaction_id = operation_instance.response_transaction.transaction_id
      expect(request_transmission_transmission_id).to eq(response_transmission_transmission_id)
      expect(request_transaction_transaction_id).to eq(response_transaction_transaction_id)
      expect(request_transmission_transmission_id).to eq(enrollment_hbx_id)
      expect(response_transmission_transmission_id).to eq(enrollment_hbx_id)
      expect(request_transaction_transaction_id).to eq(enrollment_hbx_id)
      expect(response_transaction_transaction_id).to eq(enrollment_hbx_id)
    end
  end

  after :all do
    file_path = "#{Rails.root}/log/begin_coverage_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
    File.delete(file_path) if File.file?(file_path)
  end
end
