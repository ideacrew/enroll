# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::HbxEnrollments::PublishExpirationEvent, dbclean: :after_each do
  let(:family) { FactoryBot.create(:family, :with_primary_family_member) }
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

  let(:transmittable_job) { FactoryBot.create(:transmittable_job, :hbx_enrollments_expiration) }
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
    end

    context 'with valid params' do
      before :each do
        result
      end

      it 'returns success' do
        expect(result.success).to eq(
          "Successfully published expiration event: events.individual.enrollments.expire_coverages.expire for enrollment with hbx_id: #{enrollment.hbx_id}."
        )
      end

      it 'creates transmission with correct association' do
        expect(operation_instance.transmission).to be_a(::Transmittable::Transmission)
        expect(operation_instance.transmission.job).to eq(transmittable_job)
      end

      it 'associates newly created transmission to job' do
        expect(transmittable_job.transmissions.count).to eq(1)
        expect(transmittable_job.transmissions.first).to eq(operation_instance.transmission)
      end

      it 'creates transaction with correct associations' do
        expect(operation_instance.transaction).to be_a(::Transmittable::Transaction)
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
