# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::HbxEnrollments::PublishBeginCoverageEvent, dbclean: :after_each do
  include Dry::Monads[:do, :result]

  before :each do
    DatabaseCleaner.clean
  end

  let(:family) { FactoryBot.create(:family, :with_primary_family_member) }
  let(:effective_on) { TimeKeeper.date_of_record.beginning_of_year }
  let(:aasm_state) { 'auto_renewing' }
  let!(:enrollment) do
    FactoryBot.create(
      :hbx_enrollment,
      :individual_unassisted,
      family: family,
      aasm_state: aasm_state,
      effective_on: effective_on
    )
  end

  let(:transmittable_job) do
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

  let(:job_process_status) { transmittable_job.process_status }

  let(:transmission) { operation_instance.transmission }
  let(:transmission_process_status) { transmission.process_status }

  let(:params) { { enrollment: enrollment, job: transmittable_job } }

  let(:operation_instance) { described_class.new }
  let(:result) { operation_instance.call(params) }

  describe '#call' do
    context 'with invalid params' do
      context 'when params is not a hash' do
        let(:params) { nil }

        it 'returns a failure' do
          expect(result.failure).to eq("Invalid input params: #{params}. Expected a hash.")
        end
      end

      context 'when enrollment is not a valid object' do
        let(:params) { { enrollment: 'enrollment' } }

        it 'returns a failure' do
          expect(result.failure).to eq("Invalid input params: #{params}. Expected a hash.")
        end
      end

      context 'when job is not a valid object' do
        let(:params) { { enrollment: enrollment, job: 'transmittable_job' } }

        it 'returns a failure' do
          expect(result.failure).to eq("Invalid input params: #{params}. Expected a hash.")
        end
      end

      context 'when transmission creation fails' do
        before :each do
          allow(
            ::Operations::Transmittable::CreateTransmission
          ).to receive(:new).and_return(
            double('CreateTransmission', call: Failure('Failed to create transmission due to invalid params.'))
          )

          result
        end

        it 'returns a failure monad' do
          expect(result.failure).to eq('Failed to create transmission due to invalid params.')
        end

        it 'does not create transmission' do
          expect(transmittable_job.transmissions.count).to eq(0)
          expect(operation_instance.transmission).to be_nil
          expect(Transmittable::Transmission.count).to eq(0)
        end

        it 'creates an error associated to the job' do
          expect(transmittable_job.transmittable_errors.count).to eq(1)
          expect(transmittable_job.transmittable_errors.first.key).to eq(:create_request_transmission)
          expect(Transmittable::Error.all.count).to eq(1)
          expect(Transmittable::Error.first.errorable).to eq(transmittable_job)
        end

        it 'updates the process status and creates new process state associated to the job' do
          expect(job_process_status.latest_state).to eq(:failed)
          expect(job_process_status.process_states.count).to eq(2)
          expect(job_process_status.process_states.last.state_key).to eq(:failed)
        end
      end

      context 'when transaction creation fails' do
        before :each do
          allow(
            ::Operations::Transmittable::CreateTransaction
          ).to receive(:new).and_return(
            double('CreateTransaction', call: Failure('Failed to create transaction due to invalid params.'))
          )

          result
        end

        it 'returns a failure monad' do
          expect(result.failure).to eq('Failed to create transaction due to invalid params.')
        end

        it 'does not create transaction' do
          expect(transmission.transactions.count).to eq(0)
          expect(operation_instance.transaction).to be_nil
          expect(Transmittable::Transaction.count).to eq(0)
        end

        it 'creates an error associated to the job and transmission' do
          expect(transmission.transmittable_errors.count).to eq(1)
          expect(transmission.transmittable_errors.first.key).to eq(:create_request_transaction)
          expect(transmittable_job.transmittable_errors.count).to eq(1)
          expect(transmittable_job.transmittable_errors.first.key).to eq(:create_request_transaction)
          expect(Transmittable::Error.all.count).to eq(2)
          expect(Transmittable::Error.all.map(&:errorable).sort).to eq([transmission, transmittable_job].sort)
        end

        it 'updates the process status and creates new process state associated to the job' do
          expect(job_process_status.latest_state).to eq(:failed)
          expect(job_process_status.process_states.count).to eq(2)
          expect(job_process_status.process_states.last.state_key).to eq(:failed)
          expect(transmission_process_status.latest_state).to eq(:failed)
          expect(transmission_process_status.process_states.count).to eq(2)
          expect(transmission_process_status.process_states.last.state_key).to eq(:failed)
        end
      end
    end

    context 'with valid params' do
      before :each do
        result
      end

      it 'returns success' do
        expect(result.success).to eq(
          "Successfully published begin coverage event: events.individual.enrollments.begin_coverages.begin for enrollment with hbx_id: #{enrollment.hbx_id}."
        )
      end

      it 'creates transmission with correct association' do
        expect(operation_instance.transmission).to be_a(::Transmittable::Transmission)
        expect(operation_instance.transmission.transmission_id).to eq(enrollment.hbx_id)
        expect(operation_instance.transmission.job).to eq(transmittable_job)
      end

      it 'associates newly created transmission to job' do
        expect(transmittable_job.transmissions.count).to eq(1)
        expect(transmittable_job.transmissions.first).to eq(operation_instance.transmission)
      end

      it 'creates transaction with correct associations' do
        expect(operation_instance.transaction).to be_a(::Transmittable::Transaction)
        expect(operation_instance.transaction.transaction_id).to eq(enrollment.hbx_id)
        expect(operation_instance.transaction.transactable).to eq(enrollment)
      end

      it 'creates join table record between transmission and transaction' do
        expect(
          ::Transmittable::TransactionsTransmissions.where(
            transaction_id: operation_instance.transaction.id,
            transmission_id: operation_instance.transmission.id
          ).count
        ).to eq(1)
      end

      it 'associates newly created transaction to enrollment' do
        expect(enrollment.transactions.count).to eq(1)
        expect(enrollment.transactions.first).to eq(operation_instance.transaction)
      end
    end
  end
end
