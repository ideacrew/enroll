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
  let(:result) { described_class.new.call(params) }

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
      before :each { result }

      it 'returns success' do
        expect(result.success).to eq(
          "Published expiration event: events.individual.enrollments.expire_coverages.expire for enrollment with gid: #{enrollment.to_global_id.uri}."
        )
      end

      it 'creates transmission with correct association' do
        expect(subject.transmission).to be_a(::Transmittable::Transmission)
        expect(subject.transmission.job).to eq(transmittable_job)
      end

      it 'creates transaction with correct associations' do
        expect(subject.transaction).to be_a(::Transmittable::Transaction)
        expect(subject.transaction.job).to eq(subject.transmission)
        expect(
          ::Transmittable::TransactionsTransmissions.where(
            transaction_id: subject.transaction.id,
            transmission_id: subject.transmission.id
          ).count
        ).to eq(1)
        expect(subject.transaction.transactable).to eq(enrollment)
      end

      it 'creates transaction for enrollment' do
        expect(enrollment.transactions.count).to eq(1)
        expect(enrollment.transactions.first).to eq(subject.transaction)
      end
    end
  end
end
