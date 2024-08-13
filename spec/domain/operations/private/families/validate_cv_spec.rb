# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Operations::Private::Families::ValidateCv do
  after :all do
    DatabaseCleaner.clean
  end

  describe '#call' do
    let(:result) { subject.call(input_params) }

    context 'when:
      - a valid family_hbx_id is provided
      - a valid family_updated_at is provided
      - a valid job_id is provided
      ' do

      let(:person) { FactoryBot.create(:person, :with_active_consumer_role, :with_consumer_role) }
      let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }

      let(:input_params) do
        {
          family_hbx_id: family.hbx_assigned_id,
          family_updated_at: family.updated_at,
          job_id: SecureRandom.uuid
        }
      end

      it 'returns an instance of CvValidationJob' do
        validation_job = result.success
        expect(validation_job).to be_a(CvValidationJob)
        expect(validation_job.cv_payload_creation_time).not_to be_nil
        expect(validation_job.cv_validation_job_time).not_to be_nil
      end
    end

    context 'when:
      - a valid family_hbx_id is provided
      - an invalid family_updated_at is provided
      - a valid job_id is provided
      ' do

      let(:person) { FactoryBot.create(:person, :with_active_consumer_role, :with_consumer_role) }
      let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }

      let(:input_params) do
        {
          family_hbx_id: family.hbx_assigned_id,
          family_updated_at: 'family.updated_at',
          job_id: SecureRandom.uuid
        }
      end

      it 'returns a failure monad' do
        expect(result.failure).to eq(
          "Error validating input parameters: #{input_params}. Error Message: invalid date"
        )
      end
    end

    context 'when:
      - an invalid family_hbx_id is provided
      - a valid family_updated_at is provided
      - a valid job_id is provided
      ' do

      let(:person) { FactoryBot.create(:person, :with_active_consumer_role, :with_consumer_role) }
      let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }

      let(:input_params) do
        {
          family_hbx_id: 'family.hbx_assigned_id',
          family_updated_at: family.updated_at,
          job_id: SecureRandom.uuid
        }
      end

      it 'returns a failure monad' do
        expect(result.failure).to eq(
          "Unable to find family with hbx_id: #{input_params[:family_hbx_id]}"
        )
      end
    end

    context 'when:
      - a valid family_hbx_id is provided
      - a valid family_updated_at is provided
      - an invalid job_id is provided
      ' do

      let(:person) { FactoryBot.create(:person, :with_active_consumer_role, :with_consumer_role) }
      let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }

      let(:input_params) do
        {
          family_hbx_id: family.hbx_assigned_id,
          family_updated_at: family.updated_at,
          job_id: nil
        }
      end

      it 'returns a failure monad' do
        expect(result.failure).to eq(
          "Invalid input parameters: #{input_params}. Expected keys with values: family_hbx_id, family_updated_at, and job_id."
        )
      end
    end
  end
end
