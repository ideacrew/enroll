# frozen_string_literal: true

RSpec.describe Operations::Migrations::Applications::BenchmarkPremiums::Initiate, type: :model do

  describe '#call' do
    let(:event_name) do
      'events.batch_processes.migrations.applications.benchmark_premiums.request_migration_event_batches'
    end

    context 'with valid params' do
      let(:params) { { batch_size: 10 } }

      it 'returns success' do
        expect(subject.call(params).success).to eq(
          "Successfully published event: #{event_name}."
        )
      end
    end

    context 'missing batch_size' do
      let(:params) { { dummy: nil } }

      it 'returns failure' do
        expect(subject.call(params).failure).to eq(
          "Invalid input batch size: #{params[:batch_size]}. Please provide a positive integer."
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

    context 'when event fails to publish' do
      let(:ev_event) { instance_double('EventSource::Event', name: event_name) }

      before do
        allow(ev_event).to receive(:publish).and_return(false)
      end

      it 'returns a failure monad with a failure message' do
        result = subject.send(:initiate_migration, ev_event)
        expect(result).to be_a(Dry::Monads::Failure)
        expect(result.failure).to eq("Failed to publish event: #{event_name}.")
      end
    end
  end
end
