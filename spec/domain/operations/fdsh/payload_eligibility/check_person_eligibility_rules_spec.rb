# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Operations::Fdsh::PayloadEligibility::CheckPersonEligibilityRules do
  describe 'request_type ssa' do
    let(:person) { FactoryBot.create(:person, :with_consumer_role) }
    let(:payload_entity) do
      value = Operations::Transformers::PersonTo::Cv3Person.new.call(person).success
      AcaEntities::People::Person.new(value.to_h)
    end
    let(:request_type) { :ssa }
    let(:validator) { instance_double(Operations::Fdsh::EncryptedSsnValidator) }

    context 'when all validation rules pass' do
      it 'returns a Success result' do
        result = described_class.new.call(payload_entity, request_type)
        expect(result).to be_success
      end
    end

    context 'when a validation rule fails' do
      before do
        allow(validator).to receive(:call).and_return(Dry::Monads::Failure('Invalid SSN'))
        allow(Operations::Fdsh::EncryptedSsnValidator).to receive(:new).and_return(validator)
      end

      it 'returns a Failure result' do
        result = described_class.new.call(payload_entity, request_type)
        expect(result).to be_failure
      end

      it 'returns an error message' do
        result = described_class.new.call(payload_entity, request_type)
        expect(result.failure).to eq(["Invalid SSN"])
      end
    end
  end

  describe 'request_type dhs' do
    let(:person) { FactoryBot.create(:person, :with_consumer_role) }
    let!(:person_contract) {Operations::Transformers::PersonTo::Cv3Person.new.call(person).success}
    let(:person_entity) { AcaEntities::People::Person.new(person_contract.to_h)}
    let(:request_type) { :dhs }
    let(:validator) { instance_double(Operations::Fdsh::EncryptedSsnValidator) }

    context 'when all validation rules pass' do
      it 'returns a Success result' do
        result = described_class.new.call(person_entity, request_type)
        expect(result).to be_success
      end
    end

    context 'when a ssn validation rule is not present' do
      before do
        allow(validator).to receive(:call).and_return(Dry::Monads::Failure('Invalid SSN'))
        allow(Operations::Fdsh::EncryptedSsnValidator).to receive(:new).and_return(validator)
      end

      it 'returns a Success' do
        result = described_class.new.call(person_entity, request_type)
        expect(result).to be_success
      end
    end

    context 'when document type I-327 (Reentry Permit) has missing alien_number' do
      let(:person_entity) do
        person_contract.to_h[:consumer_role][:vlp_documents][0].merge!(alien_number: nil)
        AcaEntities::People::Person.new(person_contract.to_h)
      end

      before do
        @result = described_class.new.call(person_entity, request_type)
      end

      it 'returns failure' do
        expect(@result).to be_failure
      end

      it 'returns an error message' do
        expect(@result.failure).to eq(["Missing information for document type I-327 (Reentry Permit): alien_number"])
      end
    end
  end
end