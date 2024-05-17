# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::HbxEnrollments::Expire, dbclean: :after_each do
  include Dry::Monads[:do, :result]

  let(:family)      { FactoryBot.create(:family, :with_primary_family_member) }
  let!(:enrollment) { FactoryBot.create(:hbx_enrollment, :individual_unassisted, family: family) }
  let(:transmittable_job) do
    ::Operations::Transmittable::CreateJob.new.call(
      {
        key: :hbx_enrollments_expiration,
        title: "Request expiration of all active IVL enrollments.",
        description: "Job that requests expiration of all active IVL enrollments.",
        publish_on: DateTime.now,
        started_at: DateTime.now
      }
    ).success
  end

  let(:transmission) do
    ::Operations::Transmittable::CreateTransmission.new.call(
      {
        job: transmittable_job,
        key: :hbx_enrollment_expiration_request,
        title: "Transmission request to expire enrollment with hbx id: #{enrollment.hbx_id}.",
        description: "Transmission request to expire enrollment with hbx id: #{enrollment.hbx_id}.",
        publish_on: Date.today,
        started_at: DateTime.now,
        event: 'initial',
        state_key: :initial,
        correlation_id: enrollment.hbx_id
      }
    ).success
  end

  let(:transaction) do
    ::Operations::Transmittable::CreateTransaction.new.call(
      {
        transmission: transmission,
        subject: enrollment,
        key: :hbx_enrollments_expiration_request,
        title: "Enrollment expiration request transaction for #{enrollment.hbx_id}.",
        description: "Transaction request to expire enrollment with hbx id: #{enrollment.hbx_id}.",
        publish_on: Date.today,
        started_at: DateTime.now,
        event: 'initial',
        state_key: :initial,
        correlation_id: enrollment.hbx_id
      }
    ).success
  end

  let(:job_process_status) { transmittable_job.process_status }

  let(:transmittable_transmission) { FactoryBot.create(:transmittable_transmission, job: transmittable_job) }

  describe 'with invalid params' do
    let(:params) { { transmittable_identifiers: 'test' } }
    let(:result) { described_class.new.call(params) }

    context 'failure' do
      context 'transmittable_identifiers is not a hash in params' do
        it 'returns a failure' do
          expect(result.success?).to be_falsey
          expect(result.failure).to eq("Invalid transmittable_identifiers in params: #{params}. Expected a hash.")
        end
      end

      context 'missing enrollment_gid in params' do
        let(:params) { { transmittable_identifiers: {} } }
        let(:result) { described_class.new.call(params) }

        it 'returns a failure' do
          expect(result.success?).to be_falsey
          expect(result.failure).to eq("Missing enrollment_gid in params: #{params}.")
        end
      end

      context 'missing job_gid in transmittable_identifiers params' do
        let(:params) { { enrollment_gid: "test", transmittable_identifiers: {} } }
        let(:result) { described_class.new.call(params) }

        it 'returns a failure' do
          expect(result.success?).to be_falsey
          expect(result.failure).to eq("Missing job_gid in transmittable_identifiers of params: #{params}.")
        end
      end

      context 'missing transmission_gid in transmittable_identifiers params' do
        let(:params) { { enrollment_gid: "test", transmittable_identifiers: { job_gid: "test"} } }
        let(:result) { described_class.new.call(params) }

        it 'returns a failure' do
          expect(result.success?).to be_falsey
          expect(result.failure).to eq("Missing transmission_gid in transmittable_identifiers of params: #{params}.")
        end
      end

      context 'missing transaction_gid in transmittable_identifiers params' do
        let(:params) { { enrollment_gid: "test", transmittable_identifiers: { job_gid: "test", transmission_gid: "test" } } }
        let(:result) { described_class.new.call(params) }

        it 'returns a failure' do
          expect(result.success?).to be_falsey
          expect(result.failure).to eq("Missing transaction_gid in transmittable_identifiers of params: #{params}.")
        end
      end

      context 'missing subject in transmittable_identifiers params' do
        let(:params) do
          { enrollment_gid: "test", transmittable_identifiers: { job_gid: "test", transmission_gid: "test",
                                                                 transaction_gid: "test"} }
        end
        let(:result) { described_class.new.call(params) }

        it 'returns a failure' do
          expect(result.success?).to be_falsey
          expect(result.failure).to eq("Missing subject_gid in transmittable_identifiers of params: #{params}.")
        end
      end

      context 'find_enrollment' do
        let(:params) do
          { enrollment_gid: "test", transmittable_identifiers: { job_gid: "test", transmission_gid: "test",
                                                                 transaction_gid: "test", subject_gid: "test"} }
        end
        let(:result) { described_class.new.call(params) }

        context 'invalid enrollment_gid' do
          it 'returns a failure' do
            expect(result.success?).to be_falsey
            expect(result.failure).to eq("No HbxEnrollment found with given global ID: test")
          end
        end

        context 'shop enrollment' do
          let(:params) do
            { enrollment_gid: enrollment.to_global_id.to_s,
              transmittable_identifiers: { job_gid: "test", transmission_gid: "test",
                                           transaction_gid: "test", subject_gid: "test"} }
          end
          let(:result) { described_class.new.call(params) }
          it 'returns a failure if enrollment is not IVL kind' do
            enrollment.update_attributes(kind: 'employer_sponsored')
            expect(result.success?).to be_falsey
            expect(result.failure).to eq("Failed to expire enrollment hbx id #{enrollment.hbx_id} - #{enrollment.kind} is not a valid IVL enrollment kind")
          end
        end
      end

      context 'find_job_by_global_id' do
        let(:params) do
          { enrollment_gid: enrollment.to_global_id.to_s,
            transmittable_identifiers: { job_gid: "test", transmission_gid: "test",
                                         transaction_gid: "test", subject_gid: "test"} }
        end
        let(:result) { described_class.new.call(params) }

        context 'invalid job_gid' do
          it 'returns a failure' do
            expect(result.success?).to be_falsey
            expect(result.failure).to eq("No Transmittable::Job found with given global ID: test")
          end
        end
      end

      context 'find_transmission_by_global_id' do
        let(:params) do
          { enrollment_gid: enrollment.to_global_id.to_s,
            transmittable_identifiers: { job_gid: transmittable_job.to_global_id.to_s,
                                         transmission_gid: "test",
                                         transaction_gid: "test", subject_gid: "test"} }
        end
        let(:result) { described_class.new.call(params) }

        context 'invalid transmission_gid' do
          it 'returns a failure' do
            expect(result.success?).to be_falsey
            expect(result.failure).to eq("No Transmittable::Transmission found with given global ID: test")
          end
        end
      end

      context 'find_transaction_by_global_id' do
        let(:params) do
          { enrollment_gid: enrollment.to_global_id.to_s,
            transmittable_identifiers: { job_gid: transmittable_job.to_global_id.to_s,
                                         transmission_gid: transmission.to_global_id.to_s,
                                         transaction_gid: "test", subject_gid: "test"} }
        end
        let(:result) { described_class.new.call(params) }

        context 'invalid transaction_gid' do
          it 'returns a failure' do
            expect(result.success?).to be_falsey
            expect(result.failure).to eq("No Transmittable::Transaction found with given global ID: test")
          end
        end
      end
    end
  end

  describe 'with invalid enrollment' do
    let(:params) do
      { enrollment_gid: enrollment.to_global_id.to_s,
        transmittable_identifiers: { job_gid: transmittable_job.to_global_id.to_s,
                                     transmission_gid: transmission.to_global_id.to_s,
                                     transaction_gid: transaction.to_global_id.to_s,
                                     subject_gid: enrollment.to_global_id.to_s } }
    end
    let(:operation_instance) { described_class.new }
    let(:result) { operation_instance.call(params) }

    describe 'where enrollment fails the expiration guard clause' do
      let(:benefit_group) { FactoryBot.create(:benefit_group) }

      before do
        benefit_group.plan_year.update_attributes(end_on: Date.today - 1.day)
        enrollment.update_attributes(benefit_group_id: benefit_group.id)
      end

      it 'fails due to invalid state transition to coverage_expired' do
        expect(result.success?).to be_falsey
        expect(result.failure).to match(
          /Failed to expire enrollment hbx id #{enrollment.hbx_id} - Event 'expire_coverage' cannot transition from 'coverage_selected'./
        )
      end

      it 'updates response_transmission and response_transaction' do
        result
        expect(operation_instance.response_transmission.transmittable_errors).to be_present
        expect(operation_instance.response_transmission.transmittable_errors.pluck(:key)).to include(:expire_enrollment)
        expect(operation_instance.response_transaction.transmittable_errors.pluck(:key)).to include(:expire_enrollment)
        expect(operation_instance.response_transaction.transmittable_errors.pluck(:key)).to be_present
        expect(operation_instance.response_transaction.process_status.latest_state).to eq :failed
      end
    end
  end


  describe 'with valid params' do
    let(:params) do
      { enrollment_gid: enrollment.to_global_id.to_s,
        transmittable_identifiers: { job_gid: transmittable_job.to_global_id.to_s,
                                     transmission_gid: transmission.to_global_id.to_s,
                                     transaction_gid: transaction.to_global_id.to_s,
                                     subject_gid: enrollment.to_global_id.to_s } }
    end
    let(:operation_instance) { described_class.new }
    let(:result) { operation_instance.call(params) }

    before :each do
      result
    end

    it 'succeeds with message' do
      expect(result.success?).to be_truthy
      expect(result.value!).to eq("Successfully expired enrollment hbx id #{enrollment.hbx_id}")
    end

    it 'creates transmission with correct association' do
      expect(operation_instance.response_transmission).to be_a(::Transmittable::Transmission)
      expect(operation_instance.response_transmission.job).to eq(transmittable_job)
    end

    it 'associates newly created response transmission to job' do
      expect(transmittable_job.transmissions.count).to eq(2)
      expect(transmittable_job.transmissions.pluck(:key)).to include(:hbx_enrollment_expiration_response)
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
      request_transmission = transmittable_job.transmissions.detect { |transmission| transmission.key == :hbx_enrollment_expiration_request }
      expect(request_transmission.transmission_id).to eq(enrollment.hbx_id)
      expect(operation_instance.response_transmission.transmission_id).to eq(enrollment.hbx_id)
      expect(operation_instance.response_transaction.transaction_id).to eq(enrollment.hbx_id)
    end

    describe 'where enrollment is a coverall enrollment' do
      before do
        enrollment.update_attributes(kind: 'coverall')
      end

      it 'succeeds with message' do
        expect(result.success?).to be_truthy
        expect(result.value!).to eq("Successfully expired enrollment hbx id #{enrollment.hbx_id}")
      end
    end
  end
end
