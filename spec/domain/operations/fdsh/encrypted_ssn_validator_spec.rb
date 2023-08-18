require 'rails_helper'

RSpec.describe Operations::Fdsh::EncryptedSsnValidator do
  describe '#call' do
    let(:encrypted_ssn) { 'ZH+eMirBkR03EdBbtJGFVoABu/0GLclHkA==\n' }
    let(:validator) { described_class.new }

    context 'when the encrypted SSN is valid' do
      it 'returns a Success result' do
        result = validator.call(encrypted_ssn)
        expect(result).to be_success
      end
    end

    context 'when the encrypted SSN is invalid' do
      let(:encrypted_ssn) { '5MnAXl2mKKrZYleeaOu2R4gKsfkDKsNNkw==\n' }

      it 'returns a Failure result' do
        result = validator.call(encrypted_ssn)
        expect(result).to be_failure
      end

      it 'returns an error message' do
        result = validator.call(encrypted_ssn)
        expect(result.failure).to eq('Invalid SSN')
      end
    end
  end
end