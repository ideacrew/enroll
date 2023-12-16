require 'rails_helper'

RSpec.describe Operations::Transmittable::TransmittableUtils do
  include Dry::Monads[:result]
  include Operations::Transmittable::TransmittableUtils

  let(:job) { FactoryBot.create(:transmittable_job) }
  let(:transmission) { FactoryBot.create(:transmittable_transmission) }

  describe '#find_job_by_global_id' do
    context 'when job is found' do
      it 'returns a Success result with the found job' do
        result = find_job_by_global_id(job.to_global_id.to_s)
        expect(result).to be_a(Dry::Monads::Result::Success)
        expect(result.value!).to eq(job)
      end
    end

    context 'when job is not found' do
      let(:job_gid) { 'invalid_gid' }

      it 'returns a Failure result with an error message' do
        result = find_job_by_global_id(job_gid)
        expect(result).to be_a(Dry::Monads::Result::Failure)
        expect(result.failure).to include("No Transmittable::Job found with given global ID: #{job_gid}")
      end
    end
  end

  describe '#find_transmission_by_global_id' do
    context 'when transmission is found' do
      it 'returns a Success result with the found transmission' do
        result = find_transmission_by_global_id(transmission.to_global_id.to_s)
        expect(result).to be_a(Dry::Monads::Result::Success)
        expect(result.value!).to eq(transmission)
      end
    end

    context 'when transmission is not found' do
      let(:transmission_gid) { 'invalid_gid' }

      it 'returns a Failure result with an error message' do
        result = find_transmission_by_global_id(transmission_gid)
        expect(result).to be_a(Dry::Monads::Result::Failure)
        expect(result.failure).to include("No Transmittable::Transmission found with given global ID: #{transmission_gid}")
      end
    end
  end

  describe '#find_transaction_by_global_id' do
    context 'when transaction is found' do
      let(:transaction_gid) { 'gid://enroll/Transmittable::Transaction/789' }
      let(:transaction) { double }

      it 'returns a Success result with the found transaction' do
        allow(GlobalID::Locator).to receive(:locate).with(transaction_gid).and_return(transaction)
        result = find_transaction_by_global_id(transaction_gid)
        expect(result).to be_a(Dry::Monads::Result::Success)
        expect(result.value!).to eq(transaction)
      end
    end

    context 'when transaction is not found' do
      let(:transaction_gid) { 'invalid_gid' }

      it 'returns a Failure result with an error message' do
        allow(GlobalID::Locator).to receive(:locate).with(transaction_gid).and_return(nil)
        result = find_transaction_by_global_id(transaction_gid)
        expect(result).to be_a(Dry::Monads::Result::Failure)
        expect(result.failure).to include("No Transmittable::Transaction found with given global ID: #{transaction_gid}")
      end
    end
  end
end
