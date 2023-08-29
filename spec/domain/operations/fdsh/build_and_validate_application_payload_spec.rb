# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('spec/shared_contexts/valid_cv3_application_setup.rb')

RSpec.describe Operations::Fdsh::BuildAndValidateApplicationPayload, dbclean: :after_each do
  include_context "valid cv3 application setup"

  describe '#call' do
    context 'returning a payload in during an admin FDSH hub call' do
      context 'for :income request type' do
        let(:request_type) { :income }

        context 'when all validation rules pass' do
          it 'returns a Success result' do
            result = described_class.new.call(application, request_type)
            expect(result).to be_success
          end
        end

        context 'with a malformed cv3' do
          before do
            allow(application).to receive(:applicants).and_return(nil)
          end

          it 'raises an error' do
            result = described_class.new.call(application, request_type)

            expect(result).to be_failure
            expect(result.failure).to include('Error while generating CV3 Application: ')
          end
        end

        context 'when the encrypted SSN is invalid' do
          let(:validator) { instance_double(Operations::Fdsh::EncryptedSsnValidator) }

          before do
            allow(validator).to receive(:call).and_return(Dry::Monads::Failure('Invalid SSN'))
            allow(Operations::Fdsh::EncryptedSsnValidator).to receive(:new).and_return(validator)
          end

          it 'returns a Failure result' do
            result = described_class.new.call(application, request_type)
            expect(result).to be_failure
          end

          it 'returns an error message' do
            result = described_class.new.call(application, request_type)
            expect(result.failure).to eq(['Invalid SSN'])
          end
        end
      end
    end
  end
end