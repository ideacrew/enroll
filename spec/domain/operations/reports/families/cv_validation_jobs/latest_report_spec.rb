# frozen_string_literal: true

RSpec.describe Operations::Reports::Families::CvValidationJobs::LatestReport do
  let(:job_id) { 'aksjh7d7gds7sg00000' }
  let(:create_jobs) do
    FactoryBot.create_list(:cv_validation_job, 3, :success, job_id: job_id)
  end

  describe '#call' do
    let(:result) { subject.call }

    context 'when the jobs exist' do
      let(:csv_file_name) { Dir.glob("#{Rails.root}/latest_cv_validation_job_report_#{job_id}_*.csv").first }
      let(:primary_person_hbx_ids_from_csv) do
        primary_person_hbx_ids = []

        CSV.foreach(csv_file_name, headers: true) do |row|
          primary_person_hbx_ids << row['Primary Person HBX ID']
        end

        primary_person_hbx_ids
      end

      before do
        create_jobs
      end

      it 'returns a success result' do
        expect(result).to be_success
        expect(primary_person_hbx_ids_from_csv.sort).to eq(
          CvValidationJob.where(job_id: job_id).pluck(:primary_person_hbx_id).sort
        )
      end
    end

    context 'when the jobs do not exist' do
    end
  end
end
