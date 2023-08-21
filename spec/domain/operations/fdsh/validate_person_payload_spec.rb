# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Operations::Fdsh::ValidatePersonPayload do
  describe '#call' do
    before :each do
      allow(EnrollRegistry).to receive(:feature_enabled?).and_return(false)
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:validate_and_record_publish_errors).and_return(true)
    end
    let(:person) { FactoryBot.create(:person, :with_consumer_role) }
    let(:validator) { instance_double(Operations::Fdsh::EncryptedSsnValidator) }
    let(:request_type) { :ssa }

    context 'when all validation rules pass' do
      it 'returns a Success result' do
        result = described_class.new.call(person, request_type)
        expect(result).to be_success
      end
    end

    context 'when the encrypted SSN is invalid' do
      before do
        allow(validator).to receive(:call).and_return(Dry::Monads::Failure('Invalid SSN'))
        allow(Operations::Fdsh::EncryptedSsnValidator).to receive(:new).and_return(validator)
      end

      it 'returns a Failure result' do
        result = described_class.new.call(person, request_type)
        expect(result).to be_failure
      end

      it 'returns an error message' do
        result = described_class.new.call(person, request_type)
        expect(result.failure).to eq(["Invalid SSN"])
      end
    end
  end
end