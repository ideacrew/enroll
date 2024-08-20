# frozen_string_literal: true

RSpec.describe CvValidationJob, type: :model do
  after :all do
    DatabaseCleaner.clean
  end

  let!(:success_job)            { FactoryBot.create(:cv_validation_job, result: :success) }
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
    it { is_expected.to have_field(:cv_start_time).of_type(DateTime) }
    it { is_expected.to have_field(:cv_end_time).of_type(DateTime) }
    it { is_expected.to have_field(:start_time).of_type(DateTime) }
    it { is_expected.to have_field(:end_time).of_type(DateTime) }
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

  describe '#cv_payload_transformation_time' do
    let(:cv_start_time) { DateTime.now - 60.minutes }
    let(:cv_end_time) { DateTime.now - 1.minute }
    let(:cv_validation_job) { FactoryBot.create(:cv_validation_job, cv_start_time: cv_start_time, cv_end_time: cv_end_time) }

    context 'when both cv_end_time and cv_start_time are set' do
      it 'returns the difference in seconds between cv_end_time and cv_start_time' do
        expect(cv_validation_job.cv_payload_transformation_time).to eq(3540)
      end
    end

    context 'when cv_end_time is not set' do
      let(:cv_end_time) { nil }

      it 'returns nil' do
        expect(cv_validation_job.cv_payload_transformation_time).to be_nil
      end
    end

    context 'when cv_start_time is not set' do
      let(:cv_start_time) { nil }

      it 'returns nil' do
        expect(cv_validation_job.cv_payload_transformation_time).to be_nil
      end
    end

    context 'when both cv_end_time and cv_start_time are not set' do
      let(:cv_start_time) { nil }
      let(:cv_end_time) { nil }

      it 'returns nil' do
        expect(cv_validation_job.cv_payload_transformation_time).to be_nil
      end
    end
  end

  describe '#cv_validation_job_time' do
    let(:start_time) { DateTime.now - 60.minutes }
    let(:end_time) { DateTime.now - 10.minutes }
    let(:cv_validation_job) { FactoryBot.create(:cv_validation_job, start_time: start_time, end_time: end_time) }

    context 'when both end_time and start_time are set' do
      it 'returns the difference in seconds between end_time and start_time' do
        expect(cv_validation_job.cv_validation_job_time).to eq(3000)
      end
    end

    context 'when end_time is not set' do
      let(:end_time) { nil }

      it 'returns nil' do
        expect(cv_validation_job.cv_validation_job_time).to be_nil
      end
    end

    context 'when start_time is not set' do
      let(:start_time) { nil }

      it 'returns nil' do
        expect(cv_validation_job.cv_validation_job_time).to be_nil
      end
    end

    context 'when both end_time and start_time are not set' do
      let(:start_time) { nil }
      let(:end_time) { nil }

      it 'returns nil' do
        expect(cv_validation_job.cv_validation_job_time).to be_nil
      end
    end
  end

  describe '.latest_job_id' do
    it 'returns the latest job ID' do
      expect(CvValidationJob.latest_job_id).to eq(latest_job.job_id)
    end
  end
end
