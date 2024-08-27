# frozen_string_literal: true

RSpec.describe CvValidationJob, type: :model do
  after :all do
    DatabaseCleaner.clean
  end

  let!(:success_job)            { FactoryBot.create(:cv_validation_job) }
  let!(:failure_job)            { FactoryBot.create(:cv_validation_job, result: :failure) }
  let!(:job_with_id)            { FactoryBot.create(:cv_validation_job, job_id: '12345') }
  let!(:job_with_family_hbx_id) { FactoryBot.create(:cv_validation_job, family_hbx_id: '67890') }
  let!(:latest_job)             { FactoryBot.create(:cv_validation_job, created_at: 1.day.from_now, job_id: '123723678247') }

  describe 'fields' do
    it { is_expected.to have_field(:cv_payload).of_type(String) }
    it { is_expected.to have_field(:cv_version).of_type(String) }
    it { is_expected.to have_field(:aca_version).of_type(String) }
    it { is_expected.to have_field(:aca_entities_sha).of_type(String) }
    it { is_expected.to have_field(:primary_person_hbx_id).of_type(String) }
    it { is_expected.to have_field(:family_hbx_id).of_type(String) }
    it { is_expected.to have_field(:family_updated_at).of_type(DateTime) }
    it { is_expected.to have_field(:job_id).of_type(String) }
    it { is_expected.to have_field(:result).of_type(Symbol) }
    it { is_expected.to have_field(:cv_errors).of_type(Array) }
    it { is_expected.to have_field(:logging_messages).of_type(Array) }
    it { is_expected.to have_field(:cv_payload_transformation_time).of_type(BigDecimal) }
    it { is_expected.to have_field(:job_elapsed_time).of_type(BigDecimal) }
  end

  describe 'validations' do
    let(:params) do
      {
        cv_payload: 'Sample CV Payload',
        cv_version: '3',
        aca_version: '1.0.0',
        aca_entities_sha: 'abc123',
        primary_person_hbx_id: '98765',
        family_hbx_id: '12345',
        family_updated_at: DateTime.now,
        job_id: 'job_123',
        cv_errors: [],
        logging_messages: [],
        cv_payload_transformation_time: 10.98,
        job_elapsed_time: 20.98,
        result: result
      }
    end

    context 'with invalid attributes' do
      let(:result) { :invalid }

      it 'fails to create and adds error message' do
        cv_validation_job = CvValidationJob.new(params)

        expect(cv_validation_job.save).to be_falsey
        expect(cv_validation_job).not_to be_valid
        expect(cv_validation_job.errors.messages[:result]).to include('invalid is not a valid result')
      end
    end

    context 'with valid attributes' do
      let(:result) { :error }

      it 'fails to create and adds error message' do
        cv_validation_job = CvValidationJob.new(params)

        expect(cv_validation_job.save).to be_truthy
        expect(cv_validation_job).to be_valid
        expect(cv_validation_job.errors.messages[:result]).to be_empty
      end
    end
  end

  describe 'scopes' do
    context '.success' do
      it 'returns jobs with result success' do
        expect(CvValidationJob.success).to include(success_job)
        expect(CvValidationJob.success).not_to include(failure_job)
      end
    end

    context '.failure' do
      it 'returns jobs with result failure' do
        expect(CvValidationJob.failure).to include(failure_job)
        expect(CvValidationJob.failure).not_to include(success_job)
      end
    end

    context '.by_job_id' do
      it 'returns jobs with the specified job ID' do
        expect(CvValidationJob.by_job_id('12345')).to include(job_with_id)
        expect(CvValidationJob.by_job_id('12345')).not_to include(success_job)
      end
    end

    context '.by_family_hbx_id' do
      it 'returns jobs with the specified family HBX ID' do
        expect(CvValidationJob.by_family_hbx_id('67890')).to include(job_with_family_hbx_id)
        expect(CvValidationJob.by_family_hbx_id('67890')).not_to include(success_job)
      end
    end

    context '.latest' do
      it 'returns jobs ordered by creation date descending' do
        expect(CvValidationJob.latest.first).to eq(latest_job)
      end
    end
  end

  describe 'indexes' do
    it { is_expected.to have_index_for(result: 1).with_options(name: 'result_index') }
    it { is_expected.to have_index_for(job_id: 1).with_options(name: 'job_id_index') }
    it { is_expected.to have_index_for(family_hbx_id: 1).with_options(name: 'family_hbx_id_index') }
    it { is_expected.to have_index_for(created_at: 1).with_options(name: 'created_at_index') }
  end

  describe '.latest_job_id' do
    it 'returns the latest job ID' do
      expect(CvValidationJob.latest_job_id).to eq(latest_job.job_id)
    end
  end
end
