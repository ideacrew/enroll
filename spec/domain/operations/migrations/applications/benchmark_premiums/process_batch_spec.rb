# frozen_string_literal: true

RSpec.describe Operations::Migrations::Applications::BenchmarkPremiums::ProcessBatch, type: :model do
  include Dry::Monads[:result]

  after :all do
    DatabaseCleaner.clean

    # Deletes all the log files created during the test
    Dir.glob("#{Rails.root}/log/benchmark_premiums_migration_batch_processor_*.log").each do |file|
      File.delete(file)
    end
  end

  let(:event_name) do
    'events.batch_processes.migrations.applications.benchmark_premiums.process_migration_event'
  end

  let(:person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
  let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let(:create_applications) do
    FactoryBot.create_list(:financial_assistance_application, 10, family: family, effective_date: TimeKeeper.date_of_record.beginning_of_year)
  end

  describe '#call' do
    context 'with valid params' do
      let(:params) { { batch_size: 10, skip: 0 } }

      it 'returns success' do
        create_applications
        expect(subject.call(params).success).to eq(
          "Successfully processed batch of #{params[:batch_size]} records."
        )
      end
    end

    context 'with missing params' do
      let(:params) { {} }

      it 'returns failure' do
        expect(subject.call(params).failure).to eq(
          "Invalid params: #{params}. Include both batch_size and skip."
        )
      end
    end

    context 'with invalid batch size' do
      let(:params) { { batch_size: 0, skip: 0 } }

      it 'returns failure' do
        expect(subject.call(params).failure).to eq(
          "Invalid input batch size: #{params[:batch_size]}."
        )
      end
    end

    context 'with invalid skip records' do
      let(:params) { { batch_size: 10, skip: -1 } }

      it 'returns failure' do
        expect(subject.call(params).failure).to eq(
          "Invalid input skip records: #{params[:skip]}."
        )
      end
    end
  end

  describe '#publish_event' do
    context 'unsuccessful event building' do
      let(:application) { FactoryBot.create(:financial_assistance_application, family: family) }
      let(:error_message) { 'Error building event' }
      let(:failure_monad_result) { Failure(error_message) }
      let(:logger_name) do
        "#{Rails.root}/log/benchmark_premiums_migration_batch_processor_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
      end
      let(:logger) { Logger.new(logger_name) }

      before do
        allow(subject).to receive(
          :build_event
        ).with(application.id, event_name).and_return(failure_monad_result)
        subject.instance_variable_set(:@logger, logger)
      end

      it 'logs error message' do
        subject.send(:publish_event, application, event_name)
        expect(
          File.read(logger_name)
        ).to include(
          "Failed to build event: #{event_name} for application: #{application.id} - #{error_message}"
        )
      end
    end
  end
end
