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
      it 'returns success' do
        expect(result.success).to eq(
          "Published expiration event: events.individual.enrollments.expire_coverages.expire for enrollment with gid: #{enrollment.to_global_id.uri}."
        )
      end
    end
  end
end

__END__

TODO:
  1. Add specs to verify the creation of Transmittable::Job.
  2. Add specs to verify the creation of Transmittable::Transmission.
  3. Add specs to verify the creation of Transmittable::Transaction.
  4. Add specs to verify the association of Subject to Transmittable::Transaction.
  5. What is the use of ":transmission_id" on Transmittable::Transmission?
  6. Why is ":transmission_id" a mandatory field on Transmittable::Transmission?
  7. What is the use of ":correlation_id" on Transmittable::Transmission?
