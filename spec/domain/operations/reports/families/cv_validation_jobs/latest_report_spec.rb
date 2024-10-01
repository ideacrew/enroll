# frozen_string_literal: true

RSpec.describe Operations::Reports::Families::CvValidationJobs::LatestReport do
  describe '#call' do
    let(:jobs_per_iteration) { 1 }
    let(:result) { subject.call({ jobs_per_iteration: jobs_per_iteration }) }

    # Clean up the CSVs and log file created during the test after all the tests are run.
    after :all do
      Dir.glob("#{Rails.root}/latest_cv_validation_job_report_*.csv").each do |file|
        File.delete(file)
      end

      Dir.glob("#{Rails.root}/latest_cv_validation_job_logger_*.log").each do |file|
        File.delete(file)
      end
    end

    context 'when the jobs_per_iteration is negative' do
      let(:jobs_per_iteration) { -1 }

      it 'returns a failure result' do
        expect(result).to be_failure
        expect(result.failure).to eq("Invalid jobs_per_iteration: #{jobs_per_iteration}. Please pass jobs_per_iteration as a positive integer.")
      end
    end

    context 'when the jobs_per_iteration is zero' do
      let(:jobs_per_iteration) { 0 }

      it 'returns a failure result' do
        expect(result).to be_failure
        expect(result.failure).to eq("Invalid jobs_per_iteration: #{jobs_per_iteration}. Please pass jobs_per_iteration as a positive integer.")
      end
    end

    context 'when the jobs do not exist' do
      it 'returns a failure result' do
        expect(result).to be_failure
        expect(result.failure).to eq('No CV Validation Job found')
      end
    end

    context 'when the jobs exist' do
      let(:job_id) { 'aksjh7d7gds7sg00000' }
      let(:jobs_count) { 3 }
      let(:create_jobs) do
        FactoryBot.create_list(:cv_validation_job, jobs_count, job_id: job_id)
      end

      let(:primary_person_hbx_ids_from_csv) do
        primary_person_hbx_ids = []

        # For each CSV file, read the primary person HBX ID and add it to the array.
        Dir.glob("#{Rails.root}/latest_cv_validation_job_report_*.csv").each do |file|
          CSV.foreach(file, headers: true) do |row|
            primary_person_hbx_ids << row['Primary Person HBX ID']
          end
        end

        primary_person_hbx_ids
      end

      let(:logger_content) do
        File.read(Dir.glob("#{Rails.root}/latest_cv_validation_job_logger_*.log").first)
      end

      let(:cv_job_ids) { CvValidationJob.where(job_id: job_id).pluck(:_id) }

      it '
        - returns a success result
        - logs all the bson ids of the jobs
        - populates information about jobs in CSVs
        - creates expected number of CSV files
        ' do
        create_jobs
        expect(result).to be_success

        # Read logger file and check if the job ID is present in the log.
        cv_job_ids.each { |job_bson_id| expect(logger_content).to include(job_bson_id.to_s) }

        expect(primary_person_hbx_ids_from_csv.sort).to eq(
          CvValidationJob.where(job_id: job_id).pluck(:primary_person_hbx_id).sort
        )

        expect(
          Dir.glob("#{Rails.root}/latest_cv_validation_job_report_*.csv").count
        ).to eq((jobs_count / jobs_per_iteration.to_f).ceil)
      end
    end
  end
end
