# frozen_string_literal: true

RSpec.describe Operations::Migrations::Applications::BenchmarkPremiums::RequestBatches, type: :model do

  let(:event_name) do
    'events.batch_processes.migrations.applications.benchmark_premiums.request_migration_event_batches'
  end

  let(:person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
  let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let(:create_applications) do
    FactoryBot.create_list(:financial_assistance_application, 10, family: family, effective_date: TimeKeeper.date_of_record.beginning_of_year)
  end

  let(:total_records) do
    ::FinancialAssistance::Application.count
  end

  after :all do
    DatabaseCleaner.clean

    # Deletes all the log files created during the test
    Dir.glob("#{Rails.root}/log/benchmark_premiums_migration_batch_requestor_*.log").each do |file|
      File.delete(file)
    end
  end

  describe '#call' do
    context 'with valid params' do
      let(:params) { { batch_size: 10 } }

      it 'returns success' do
        create_applications
        expect(subject.call(params).success).to eq(
          "Successfully published event: #{event_name} for #{total_records} records."
        )
      end
    end

    context 'missing batch_size' do
      let(:params) { { dummy: nil } }

      it 'returns failure' do
        expect(subject.call(params).failure).to eq(
          "Missing input for batch_size: #{params[:batch_size]}."
        )
      end
    end

    context 'invalid datatype value for batch_size' do
      let(:params) { { batch_size: 'test' } }

      it 'returns failure' do
        expect(subject.call(params).failure).to eq(
          "Invalid input batch size: #{params[:batch_size]}. Please provide a positive integer."
        )
      end
    end

    context 'non-positive integer value for batch_size' do
      let(:params) { { batch_size: 0 } }

      it 'returns failure' do
        expect(subject.call(params).failure).to eq(
          "Invalid input batch size: #{params[:batch_size]}. Please provide a positive integer."
        )
      end
    end
  end

  describe '#initialize_logger' do
    it 'initializes the logger' do
      expect(subject.send(:initialize_logger).success).to be_a(Logger)
    end
  end

  describe '#request_batches' do
    let(:batch_size) { 10 }

    it 'processes batches correctly' do
      create_applications
      expect(subject.send(:request_batches, batch_size).success).to eq(
        "Successfully published event: #{event_name} for #{total_records} records."
      )
    end
  end

  describe '#request_batch' do
    let(:batch_size) { 10 }
    let(:records_processed) { 0 }

    it 'requests a single batch and publishes the event' do
      expect { subject.send(:request_batch, batch_size, event_name, records_processed) }.not_to raise_error
    end
  end

  describe '#build_event' do
    let(:batch_size) { 10 }
    let(:records_processed) { 0 }

    it 'builds the event correctly' do
      event = subject.send(:build_event, batch_size, event_name, records_processed)
      expect(event.success).to be_a(Events::BatchProcesses::Migrations::Applications::BenchmarkPremiums::RequestMigrationEventBatches)
    end
  end
end
