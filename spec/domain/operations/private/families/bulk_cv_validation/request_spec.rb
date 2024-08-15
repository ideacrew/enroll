# frozen_string_literal: true

RSpec.describe Operations::Private::Families::BulkCvValidation::Request do
  let(:family1) { FactoryBot.create(:family, :with_primary_family_member) }
  let(:family2) { FactoryBot.create(:family, :with_primary_family_member) }
  let(:family3) { FactoryBot.create(:family, :with_primary_family_member) }

  after :each do
    DatabaseCleaner.clean

    # Finds all CSV report files matching the pattern and deletes each file
    Dir.glob("#{Rails.root}/bulk_cv_validation_report_*.csv").each do |file|
      FileUtils.rm(file)
    end

    # Finds all Logger files matching the pattern and deletes each file
    Dir.glob("#{Rails.root}/bulk_cv_validation_logger_*.log").each do |file|
      FileUtils.rm(file)
    end
  end

  describe '#call' do
    let(:result) { subject.call }

    let(:expected_file_contents) do
      ::Family.only(:_id, :hbx_assigned_id, :updated_at).map do |family|
        [family.hbx_assigned_id.to_s, family.updated_at.to_s, job_id, 'Success']
      end.sort
    end

    let(:csv_file_name) { Dir.glob("#{Rails.root}/bulk_cv_validation_report_*.csv").first }
    let(:job_id) { csv_file_name.match(/bulk_cv_validation_report_(.*).csv/)[1] }
    let(:csv_file_contents) { CSV.read(csv_file_name, headers: true).map(&:fields).sort }

    before do
      family1
      family2
      family3
      result
    end

    it 'returns success moand with a message' do
      expect(result.success).to match(
        %r{Events triggered for all the families. CSV file named #{Rails.root}/bulk_cv_validation_report_(.*).csv is generated with the results.}
      )
    end

    it 'creates a CSV file with the results' do
      expect(csv_file_contents).to eq(expected_file_contents)
    end
  end
end
