# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Operations::Transmittable::CreateTransmission, dbclean: :after_each do
  subject { described_class.new }
  let(:key) { :ssa_verification_request}
  let(:title) { 'SSA Verification Request'}
  let(:description) { 'Request for SSA verification to CMS'}
  let(:job) { FactoryBot.create(:transmittable_job) }
  let(:required_params) do
    {
      key: key,
      started_at: DateTime.now,
      job: job,
      event: 'initial',
      state_key: :initial,
      correlation_id: "correration_id_123"
    }
  end

  let(:optional_params) do
    {
      title: title,
      description: description
    }
  end

  let(:all_params) { required_params.merge(optional_params) }

  context 'sending invalid params' do
    context 'key' do
      it 'should return a failure with missing key' do
        result = subject.call(required_params.except(:key))
        expect(result.failure).to eq('Transmission cannot be created without key symbol')
      end

      it 'should return a failure when key is not a symbol' do
        required_params[:key] = "Key"
        result = subject.call(required_params)
        expect(result.failure).to eq('Transmission cannot be created without key symbol')
      end
    end

    context 'started_at' do
      it 'should return a failure with missing started_at' do
        result = subject.call(required_params.except(:started_at))
        expect(result.failure).to eq('Transmission cannot be created without started_at datetime')
      end

      it 'should return a failure when started_at is not a Datetime' do
        required_params[:started_at] = Date.today
        result = subject.call(required_params)
        expect(result.failure).to eq('Transmission cannot be created without started_at datetime')
      end
    end

    context 'job' do
      it 'should return a failure with missing transmission' do
        result = subject.call(required_params.except(:job))
        expect(result.failure).to eq('Transmission cannot be created without a job')
      end

      it 'should return a failure when transmission is not a transmission object' do
        required_params[:job] = Date.today
        result = subject.call(required_params)
        expect(result.failure).to eq('Transmission cannot be created without a job')
      end
    end

    context 'event' do
      it 'should return a failure with missing event' do
        result = subject.call(required_params.except(:event))
        expect(result.failure).to eq('Transmission cannot be created without event string')
      end

      it 'should return a failure when event is not a string' do
        required_params[:event] = Date.today
        result = subject.call(required_params)
        expect(result.failure).to eq('Transmission cannot be created without event string')
      end
    end

    context 'state_key' do
      it 'should return a failure with missing state_key' do
        result = subject.call(required_params.except(:state_key))
        expect(result.failure).to eq('Transmission cannot be created without state_key symbol')
      end

      it 'should return a failure with missing state_key' do
        required_params[:state_key] = Date.today
        result = subject.call(required_params)
        expect(result.failure).to eq('Transmission cannot be created without state_key symbol')
      end
    end

    context 'correlation_id' do
      it 'should return a failure with missing state_key' do
        result = subject.call(required_params.except(:correlation_id))
        expect(result.failure).to eq('Transmission cannot be created without correlation_id string')
      end

      it 'should return a failure with missing state_key' do
        required_params[:correlation_id] = Date.today
        result = subject.call(required_params)
        expect(result.failure).to eq('Transmission cannot be created without correlation_id string')
      end
    end
  end

  context 'sending valid params' do
    before do
      @result = subject.call(all_params)
    end

    it "Should not have any errors" do
      expect(@result.success?).to be_truthy
    end

    it 'should generate a transaction' do
      expect(@result.value!.class).to eq Transmittable::Transmission
    end
  end
end
